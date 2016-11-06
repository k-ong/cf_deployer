require 'spec_helper'

describe CfDeployer::Driver::Instance do
  context '#status' do
    it 'should build the right hash of instance info' do
      expected = { :status => :pending,
                   :public_ip_address => '4.3.2.1',
                   :private_ip_address => '192.168.1.10',
                   :image_id => 'ami-testami',
                   :key_pair => 'test_pair'
                 }


      aws = double Aws::EC2::Client
      expect(Aws::EC2::Client).to receive(:new) { aws }.twice

      instance_collection = double Aws::EC2::Client
      expect(aws).to receive(:instances) { instance_collection }

      instance = Fakes::Instance.new expected.merge( { :id => 'i-wxyz1234' } )
      expect(instance_collection).to receive(:[]).with(instance.id) { instance }

      instance_status = CfDeployer::Driver::Instance.new('i-wxyz1234').status

      expected.each do |key, val|
        expect(instance_status[key]).to eq(val)
      end
    end
  end
end