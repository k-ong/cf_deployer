module CfDeployer
  module Driver
    class CloudFormation

      def initialize stack_name
        @stack_name = stack_name
      end

      def stack_exists?
        aws_stack.exists?
      end

      def create_stack template, opts
        CfDeployer::Driver::DryRun.guard "Skipping create_stack" do
          cloud_formation.create_stack({ stack_name: @stack_name, template_body: template }.merge(opts))
        end
      end

      def update_stack template, opts
        begin
          CfDeployer::Driver::DryRun.guard "Skipping update_stack" do
            cloud_formation.update_stack({ stack_name: @stack_name, template_body: template }.merge(opts))
          end

        rescue Aws::CloudFormation::Errors::ValidationError => e
          if e.message =~ /No updates are to be performed/
            Log.info e.message
            return false
          else
            raise
          end
        end

        return !CfDeployer::Driver::DryRun.enabled?
      end

      def stack_status
        aws_stack.stack_status.downcase.to_sym
      end

      def outputs
        aws_stack.outputs.inject({}) do |memo, o|
          memo[o.output_key] = o.output_value
          memo
        end
      end

      def parameters
        aws_stack.parameters.inject({}) do |memo, o|
          memo[o.parameter_key] = o.parameter_value
          memo
        end
      end

      def query_output key
        output = aws_stack.outputs.find { |o| o.output_key == key }
        output && output.output_value
      end

      def delete_stack
        if stack_exists?
          CfDeployer::Driver::DryRun.guard "Skipping create_stack" do
            aws_stack.delete
          end
        else
          Log.info "Stack #{@stack_name} does not exist!"
        end
      end

      def resource_statuses
        resources = {}
        aws_stack.resource_summaries.each do |rs|
          resources[rs[:resource_type]] ||= {}
          resources[rs[:resource_type]][rs[:physical_resource_id]] = rs[:resource_status]
        end
        resources
      end

      def template
        cloud_formation.get_template({stack_name: @stack_name})
      end

      private

      def cloud_formation
        Aws::CloudFormation::Client.new
      end

      def aws_stack
        stack_resource = Aws::CloudFormation::Resource.new(client: cloud_formation)
        stack_resource.stack(@stack_name)
      end

    end

  end
end
