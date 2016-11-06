require 'spec_helper'

describe 'CloudFormation' do
  let(:outputs) { [output1, output2] }
  let(:output1) { double('output1', :output_key => 'key1', :output_value => 'value1')}
  let(:output2) { double('output2', :output_key => 'key2', :output_value => 'value2')}
  let(:parameters) { [parameter1] }
  let(:parameter1) { double('parameter1', :parameter_key => 'key1', :parameter_value => 'value1')}
  let(:resource_summaries) { [
      {
          :resource_type => 'AWS::AutoScaling::AutoScalingGroup',
          :physical_resource_id => 'asg_1',
          :resource_status => 'STATUS_1'
      },
      {
          :resource_type => 'AWS::AutoScaling::LaunchConfiguration',
          :physical_resource_id => 'launch_config_1',
          :resource_status => 'STATUS_2'
      },
      {
          :resource_type => 'AWS::AutoScaling::AutoScalingGroup',
          :physical_resource_id => 'asg_2',
          :resource_status => 'STATUS_2'
      }
  ] }
  let(:stack) { double('stack', :outputs => outputs, :parameters => parameters, :resource_summaries => resource_summaries) }
  let(:cloudFormation) {
    double('cloudFormation',
      :describe_stacks => {'testStack' => stack}
    )
  }
  let(:cloudFormationResource) {
    double('cloudFormationResource', 'stack' => stack)
  }

  before(:each) do
    allow(Aws::CloudFormation::Client).to receive(:new) { cloudFormation }
    allow(Aws::CloudFormation::Resource).to receive(:new) { cloudFormationResource }
  end

  it 'should get outputs of stack' do
    CfDeployer::Driver::CloudFormation.new('testStack').outputs.should eq({'key1' => 'value1', 'key2' => 'value2'})
  end

  it 'should get parameters of stack' do
    CfDeployer::Driver::CloudFormation.new('testStack').parameters.should eq({'key1' => 'value1'})
  end

  context 'update_stack' do
    it 'skips the stack update if dry run is enabled' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:update_stack).with({:stack_name=>"my_stack", :template_body=>:template}).never

      CfDeployer::Driver::DryRun.enable_for do
        cloud_formation.update_stack :template, {}
      end
    end

    it 'returns false if no updates were performed (because of dry run)' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:update_stack).with(:template, {})
      result = nil

      CfDeployer::Driver::DryRun.enable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_false
    end

    it 'returns false if no updates were performed (because no difference in template)' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:update_stack).with(:template, {})
      result = nil

      CfDeployer::Driver::DryRun.disable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_false
    end

    it 'returns true when updates are performed' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      aws_stack = double(:update => :did_something)
      expect(cloud_formation).to receive(:update_stack).with(:template, {}).and_return aws_stack
      result = nil

      CfDeployer::Driver::DryRun.disable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_true
    end

  end

  context 'resource_statuses' do
    it 'should get resource statuses' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      # expect(cloud_formation).to receive(:aws_stack)
      expected = {
          'AWS::AutoScaling::AutoScalingGroup' => {
              'asg_1' => 'STATUS_1',
              'asg_2' => 'STATUS_2'
          },
          'AWS::AutoScaling::LaunchConfiguration' => {
              'launch_config_1' => 'STATUS_2'
          }
      }

      CfDeployer::Driver::CloudFormation.new('testStack').resource_statuses.should eq(expected)
    end
  end
end
