#! /usr/bin/env ruby -S rspec
shared_examples_for "Puppet::FileServing::Files" do
  it "should use the rest terminus when the 'puppet' URI scheme is used and a host name is present" do
    uri = "puppet://myhost/fakemod/my/file"

    # It appears that the mocking somehow interferes with the caching subsystem.
    # This mock somehow causes another terminus to get generated.
    term = @indirection.terminus(:rest)
    @indirection.stubs(:terminus).with(:rest).returns term
    term.expects(:find)
    @indirection.find(uri)
  end

  it "should use the rest terminus when the 'puppet' URI scheme is used, no host name is present, and default_file_terminus is rest" do
    uri = "puppet:///fakemod/my/file"
    Puppet[:default_file_terminus] = "rest"
    @indirection.terminus(:rest).expects(:find)
    @indirection.find(uri)
  end

  it "should use the file_server terminus when the 'puppet' URI scheme is used, no host name is present, and default_file_terminus is file_server" do
    uri = "puppet:///fakemod/my/file"
    Puppet::Node::Environment.stubs(:new).returns(stub("env", :name => "testing", :module => nil, :modulepath => []))
    Puppet[:default_file_terminus] = "file_server"
    Puppet[:fileserverconfig] = "/whatever"
    @indirection.terminus(:file_server).expects(:find)
    @indirection.terminus(:file_server).stubs(:authorized?).returns(true)
    @indirection.find(uri)
  end

  it "should use the file terminus when the 'file' URI scheme is used" do
    uri = Puppet::Util.path_to_uri(File.expand_path('/fakemod/my/other file'))
    uri.scheme.should == 'file'
    @indirection.terminus(:file).expects(:find)
    @indirection.find(uri.to_s)
  end

  it "should use the file terminus when a fully qualified path is provided" do
    uri = File.expand_path("/fakemod/my/file")
    @indirection.terminus(:file).expects(:find)
    @indirection.find(uri)
  end

  it "should use the configuration to test whether the request is allowed" do
    uri = "fakemod/my/file"
    mount = mock 'mount'
    config = stub 'configuration', :split_path => [mount, "eh"]
    @indirection.terminus(:file_server).stubs(:configuration).returns config

    @indirection.terminus(:file_server).expects(:find)
    mount.expects(:allowed?).returns(true)
    @indirection.find(uri, :node => "foo", :ip => "bar")
  end
end
