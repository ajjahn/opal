require 'opal/version'
require 'opal/nodes/scope'

module Opal
  module Nodes
    # Generates code for an entire file, i.e. the base sexp
    class TopNode < ScopeNode
      handle :top

      children :body

      def compile
        push version_comment

        line "(function($opal) {"

        in_scope do
          body_code = stmt(stmts)
          body_code = [body_code] unless body_code.is_a?(Array)

          add_temp 'self = $opal.top'
          add_temp '$scope = $opal'
          add_temp 'nil = $opal.nil'

          add_used_helpers
          line scope.to_vars

          compile_method_stubs
          compile_irb_vars

          line body_code
        end

        line "})(Opal);\n"
      end

      def stmts
        compiler.returns(body)
      end

      def compile_irb_vars
        if compiler.irb?
          line "if (!$opal.irb_vars) { $opal.irb_vars = {}; }"
        end
      end

      def add_used_helpers
        helpers = compiler.helpers.to_a
        helpers.to_a.each { |h| add_temp "$#{h} = $opal.#{h}" }
      end

      def compile_method_stubs
        if compiler.method_missing?
          calls = compiler.method_calls
          stubs = calls.to_a.map { |k| "'$#{k}'" }.join(', ')
          line "$opal.add_stubs([#{stubs}]);"
        end
      end

      def version_comment
        "/* Generated by Opal #{Opal::VERSION} */"
      end
    end
  end
end
