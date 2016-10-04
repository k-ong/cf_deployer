require 'spec_helper'

describe 'CloudFormation' do
  let(:outputs) { [output1, output2] }
  let(:output1) { double('output1', :key => 'key1', :value => 'value1')}
  let(:output2) { double('output2', :key => 'key2', :value => 'value2')}
  let(:parameters) { double('parameters')}
  let(:resource_summaries) { [
      {
          :resource_type => 'Aws::AutoScaling::AutoScalingGroup',
          :physical_resource_id => 'asg_1',
          :resource_status => 'STATUS_1'
      },
      {
          :resource_type => 'Aws::AutoScaling::LaunchConfiguration',
          :physical_resource_id => 'launch_config_1',
          :resource_status => 'STATUS_2'
      },
      {
          :resource_type => 'Aws::AutoScaling::AutoScalingGroup',
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

  before(:each) do
    allow(Aws::CloudFormation::Client).to receive(:new) { cloudFormation }
  end

  it 'should get outputs of stack' do
    CfDeployer::Driver::CloudFormation.new('testStack').outputs.should eq({'key1' => 'value1', 'key2' => 'value2'})
  end

  it 'should get parameters of stack' do
    CfDeployer::Driver::CloudFormation.new('testStack').parameters.should eq(parameters)
  end

  context 'update_stack' do
    it 'skips the stack update if dry run is enabled' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:update_stack).never

      CfDeployer::Driver::DryRun.enable_for do
        cloud_formation.update_stack :template, {}
      end
    end

    it 'returns false if no updates were performed (because of dry run)' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:update_stack).with('my_stack', :template, {})
      result = nil

      CfDeployer::Driver::DryRun.enable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_false
    end

    it 'returns false if no updates were performed (because no difference in template)' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      expect(cloud_formation).to receive(:aws_stack).and_raise(Aws::CloudFormation::Errors::ValidationError.new(Seahorse::Client::RequestContext.new, 'No updates are to be performed'))
      result = nil

      CfDeployer::Driver::DryRun.disable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_false
    end

    it 'returns true when updates are performed' do
      cloud_formation = CfDeployer::Driver::CloudFormation.new 'my_stack'
      aws_stack = double(:update => :did_something)
      expect(cloud_formation).to receive(:aws_stack).and_return aws_stack
      result = nil

      CfDeployer::Driver::DryRun.disable_for do
        result = cloud_formation.update_stack :template, {}
      end

      expect(result).to be_true
    end

  end

  context 'resource_statuses' do
    it 'should get resource statuses' do
      expected = {
          'Aws::AutoScaling::AutoScalingGroup' => {
              'asg_1' => 'STATUS_1',
              'asg_2' => 'STATUS_2'
          },
          'Aws::AutoScaling::LaunchConfiguration' => {
              'launch_config_1' => 'STATUS_2'
          }
      }

      CfDeployer::Driver::CloudFormation.new('testStack').resource_statuses.should eq(expected)
    end
  end
end
