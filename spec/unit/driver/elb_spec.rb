require 'spec_helper'

describe CfDeployer::Driver::ElasticLoadBalancing do
  it 'should get dns name and hosted zone id' do
    elb_hash = double('elb_hash', :dns_name => 'mydns', :canonical_hosted_zone_name_id => 'zone_id')
    elb = double('elb', :load_balancer_descriptions => {'load_balancer_descriptions' => [elb_hash]})
    aws = double('aws', :describe_load_balancers => {'myelb' => [elb]})
    elb_name = 'myelb'
    expect(Aws::ElasticLoadBalancing::Client).to receive(:new){aws}
    CfDeployer::Driver::ElasticLoadBalancing.new.find_dns_and_zone_id(elb_name).should eq({:dns_name => 'mydns', :canonical_hosted_zone_name_id => 'zone_id'})
  end
end
