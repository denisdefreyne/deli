# frozen_string_literal: true

module Deli
  class Evaluator < AbstractWalker
    class Env
      attr_reader :parent

      def initialize(parent: nil)
        @parent = parent

        @values = {}
      end

      def lookup(symbol, span)
        unless symbol
          raise 'symbol cannot be nil'
        end

        @values.fetch(symbol) do
          if @parent
            @parent.lookup(symbol, span)
          else
            raise Deli::LocatableError.new(
              "Unknown name: #{symbol.name}",
              span,
            )
          end
        end
      end

      def assign_new(symbol, value)
        @values[symbol] = value
      end

      def assign_existing(symbol, value, span)
        unless symbol
          raise 'symbol cannot be nil'
        end

        if @values.key?(symbol)
          @values[symbol] = value
        elsif @parent
          @parent.assign_existing(symbol, value, span)
        else
          raise Deli::LocatableError.new(
            "Unknown name: #{symbol.name}",
            span,
          )
        end
      end
    end

    class Fun
      attr_reader :params
      attr_reader :body_stmt
      attr_reader :this_symbol

      def initialize(params, body_stmt, this_symbol)
        @params = params
        @body_stmt = body_stmt
        @this_symbol = this_symbol
      end
    end

    class DeliStruct
      attr_reader :ident
      attr_reader :props
      attr_reader :methods

      def initialize(ident, props, methods)
        @ident = ident
        @props = props
        @methods = methods
      end

      def to_s
        ident.name
      end
    end

    class Instance
      attr_reader :struct
      attr_reader :ivars

      def initialize(struct, ivars)
        @struct = struct
        @ivars = ivars
      end

      def to_s
        "a #{struct}(#{ivars.map { |k, v| [k, '=', v.inspect].join }.join(', ')})"
      end
    end

    class Method
      attr_reader :function
      attr_reader :instance

      def initialize(function, instance)
        @function = function
        @instance = instance
      end
    end

    def initialize(stmts)
      super(stmts)

      @env = Env.new
    end

    private

    def handle_var_stmt(stmt)
      value = handle(stmt.expr)
      @env.assign_new(stmt.symbol, value)
    end

    def handle_print_stmt(stmt)
      value = handle(stmt.expr)
      puts(stringify(value))
    end

    def handle_if_stmt(stmt)
      value = handle(stmt.cond_expr)
      if value
        handle(stmt.true_stmt)
      elsif stmt.false_stmt
        handle(stmt.false_stmt)
      end
    end

    def handle_while_stmt(stmt)
      while handle(stmt.cond_expr)
        handle(stmt.body_stmt)
      end
    end

    def handle_group_stmt(stmt)
      push_env do
        stmt.stmts.each { handle(_1) }
      end
    end

    def handle_fun_stmt(stmt)
      fn = Fun.new(stmt.params, stmt.body_stmt, nil)
      @env.assign_new(stmt.symbol, fn)
    end

    def handle_struct_stmt(stmt)
      methods = {}
      stmt.methods.each do |m|
        methods[m.ident.value] = Fun.new(m.params, m.body_stmt, m.this_symbol)
      end

      struct = DeliStruct.new(stmt.symbol, stmt.props, methods)

      @env.assign_new(stmt.symbol, struct)
    end

    def handle_expr_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_return_stmt(stmt)
      if stmt.expr
        throw :return, handle(stmt.expr)
      else
        throw :return
      end
    end

    def handle_integer_expr(expr)
      expr.value
    end

    def handle_string_part_lit_expr(expr)
      expr.value
    end

    def handle_string_part_interp_expr(expr)
      handle(expr.expr).to_s
    end

    def handle_string_expr(expr)
      expr.parts.map { |part| handle(part) }.join
    end

    def handle_identifier_expr(expr)
      @env.lookup(expr.symbol, expr.ident.span)
    end

    def handle_call_expr(expr)
      callee = handle(expr.callee)

      function = nil
      instance = nil

      case callee
      when Fun
        function = callee
      when Method
        function = callee.function
        instance = callee.instance
      else
        # TODO: raise locatable error
        raise 'nope'
      end

      unless function.params.size == expr.arg_exprs.size
        raise 'args count mismatch'
      end

      push_env do
        if function.this_symbol
          @env.assign_new(function.this_symbol, instance)
        end

        function.params.zip(expr.arg_exprs) do |param, arg_expr|
          @env.assign_new(param.symbol, handle(arg_expr))
        end

        catch :return do
          handle(function.body_stmt)
        end
      end
    end

    def handle_dot_expr(expr)
      target = handle(expr.target)

      unless target.is_a?(Instance)
        raise Deli::LocatableError.new(
          'Cannot get property of something that is not a struct instance',
          expr.ident.span,
        )
      end

      # Find ivar
      if target.ivars.key?(expr.ident.value)
        return target.ivars[expr.ident.value]
      end

      # Find and bind method
      function = target.struct.methods[expr.ident.value]
      if function
        return Method.new(function, target)
      end

      raise Deli::LocatableError.new(
        "No such property: #{expr.ident.value}",
        expr.ident.span,
      )
    end

    def handle_true_expr(_expr)
      true
    end

    def handle_false_expr(_expr)
      false
    end

    def handle_null_expr(_expr)
      nil
    end

    def handle_assign_expr(expr)
      case expr.left_expr
      when AST::IdentifierExpr
        right_value = handle(expr.right_expr)
        @env.assign_existing(
          expr.left_expr.symbol,
          right_value,
          expr.left_expr.ident.span,
        )
      when AST::DotExpr
        target = handle(expr.left_expr.target)

        unless target.is_a?(Instance)
          raise Deli::LocatableError.new(
            'Cannot get property of something that is not a struct instance',
            expr.ident.span,
          )
        end

        right_value = handle(expr.right_expr)

        target.ivars[expr.left_expr.ident.value] =
          right_value
      else
        raise Deli::LocatableError.new(
          'Left-hand side cannot be assigned to',
          expr.token.span,
        )
      end
    end

    def handle_unary_expr(expr)
      val = handle(expr.expr)

      case expr.op.type
      when TokenType::PLUS
        val
      when TokenType::MINUS
        -val
      when TokenType::BANG
        !val
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected unary operator: #{expr.op}"
      end
    end

    def handle_binary_expr(expr)
      left_val = handle(expr.left_expr)
      right_val = handle(expr.right_expr)

      case expr.op.type
      when TokenType::PLUS
        left_val + right_val
      when TokenType::MINUS
        left_val - right_val
      when TokenType::ASTERISK
        left_val * right_val
      when TokenType::SLASH
        left_val / right_val
      when TokenType::LT
        left_val < right_val
      when TokenType::LTE
        left_val <= right_val
      when TokenType::GT
        left_val > right_val
      when TokenType::GTE
        left_val >= right_val
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected unary operator: #{expr.op}"
      end
    end

    def handle_new_expr(expr)
      struct = @env.lookup(expr.symbol, expr.ident.span)

      hash = {}
      struct.props.each do |prop|
        kwarg = expr.kwargs.find { |kwa| kwa.key.lexeme == prop.name.lexeme }

        unless kwarg
          raise Deli::LocatableError.new(
            "Required prop not specified: #{prop.name.lexeme}",
            expr.ident.span,
          )
        end

        hash[prop.name.lexeme] = handle(kwarg.value)
      end

      # Find superfluous
      expr.kwargs.each do |kwarg|
        prop = struct.props.find { |pr| kwarg.key.lexeme == pr.name.lexeme }

        unless prop
          raise Deli::LocatableError.new(
            "Unknown prop specified: #{kwarg.key.lexeme}",
            kwarg.key.span,
          )
        end
      end

      Instance.new(struct, hash)
    end

    def push_env
      @env = Env.new(parent: @env)
      yield
    ensure
      @env = @env.parent
    end

    def stringify(obj)
      case obj
      when nil
        'null'
      else
        obj.to_s
      end
    end
  end
end
