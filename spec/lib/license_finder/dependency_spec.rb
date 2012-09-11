require 'spec_helper'

describe LicenseFinder::Dependency do
  let(:attributes) do
    {
        'name' => "spec_name",
        'version' => "2.1.3",
        'license' => "GPL",
        'approved' => false,
        'license_url' => 'http://www.apache.org/licenses/LICENSE-2.0.html',
        'notes' => 'some notes',
        'license_files' => [{'path' => '/Users/pivotal/foo/lic1'}, {'path' => '/Users/pivotal/bar/lic2'}],
        'readme_files' => [{'path' => '/Users/pivotal/foo/Readme1'}, {'path' => '/Users/pivotal/bar/Readme2'}],
        'source' => "bundle"
    }
  end

  before do
    stub(LicenseFinder).config.stub!.whitelist { %w(MIT) }
  end

  describe '.new' do
    it "should mark it as approved when the license is whitelisted" do
      dependency = LicenseFinder::Dependency.new(attributes.merge('license' => 'MIT', 'approved' => false))
      dependency.approved.should == true
    end

    it "should not mark it as approved when the license is not whitelisted" do
      dependency = LicenseFinder::Dependency.new(attributes.merge('license' => 'GPL', 'approved' => false))
      dependency.approved.should == false
    end

    it "should leave it as approved when the license is not whitelisted but it has already been marked as approved" do
      dependency = LicenseFinder::Dependency.new(attributes.merge('license' => 'GPL', 'approved' => true))
      dependency.approved.should == true
    end
  end


  describe '.from_hash' do
    subject { LicenseFinder::Dependency.from_hash(attributes) }

    its(:name) { should == 'spec_name' }
    its(:version) { should == '2.1.3' }
    its(:license) { should == 'GPL' }
    its(:approved) { should == false }
    its(:license_url) { should == "http://www.apache.org/licenses/LICENSE-2.0.html" }
    its(:notes) { should == "some notes" }
    its(:license_files) { should == ["/Users/pivotal/foo/lic1", "/Users/pivotal/bar/lic2"] }
    its(:readme_files) { should == ["/Users/pivotal/foo/Readme1", "/Users/pivotal/bar/Readme2"] }
    its(:source) { should == "bundle" }
    its(:as_yaml) do
      should == {
        'name' => 'spec_name',
        'version' => '2.1.3',
        'license' => 'GPL',
        'approved' => false,
        'source' => 'bundle',
        'license_url' => 'http://www.apache.org/licenses/LICENSE-2.0.html',
        'notes' => 'some notes',
        'license_files' => [
          {'path' => '/Users/pivotal/foo/lic1'},
          {'path' => '/Users/pivotal/bar/lic2'}
        ],
        'readme_files' => [
          {'path' => '/Users/pivotal/foo/Readme1'},
          {'path' => '/Users/pivotal/bar/Readme2'}
        ]
      }
    end

    it 'should generate yaml' do
      yaml = YAML.load(subject.to_yaml)
      yaml.should == subject.as_yaml
    end
  end

  describe '#source' do
    it "should default to nil" do
      LicenseFinder::Dependency.new.source.should be_nil
    end

    it "should be overridable" do
      LicenseFinder::Dependency.new("source" => "foo").source.should == "foo"
    end
  end

  describe '#merge' do
    subject do
      LicenseFinder::Dependency.new(
        'name' => 'foo',
        'license' => 'MIT',
        'version' => '0.0.1',
        'license_url' => 'http://www.example.com/license1.htm',
        'license_files' => "old license files",
        'readme_files' => "old readme files",
      )
    end

    let(:new_dep) do
      LicenseFinder::Dependency.new(
        'name' => 'foo',
        'license' => 'MIT',
        'version' => '0.0.2',
        'license_url' => 'http://www.example.com/license2.htm',
        'license_files' => "new license files",
        'readme_files' => "new readme files"
      )
    end

    it 'should raise an error if the names do not match' do
      new_dep.name = 'bar'

      expect {
        subject.merge(new_dep)
      }.to raise_error
    end

    it 'should return the new version, license url, license files, readme files, and source' do
      merged = subject.merge(new_dep)

      merged.version.should == '0.0.2'
      merged.license_url.should == 'http://www.example.com/license2.htm'
      merged.license_files.should == new_dep.license_files
      merged.readme_files.should == new_dep.readme_files
      merged.source.should == new_dep.source
    end

    it 'should return the old notes' do
      subject.notes = 'old notes'
      new_dep.notes = 'new notes'

      merged = subject.merge(new_dep)

      merged.notes.should == 'old notes'
    end

    it 'should return the new license and approval if the license is different' do
      subject.license = "MIT"
      subject.approved = true

      new_dep.license = "GPLv2"
      new_dep.approved = false

      merged = subject.merge(new_dep)

      merged.license.should == "GPLv2"
      merged.approved.should == false
    end

    it 'should return the old license and approval if the new license is the same or "other"' do
      subject.approved = false
      new_dep.approved = true

      subject.merge(new_dep).approved.should == false

      new_dep.license = 'other'

      subject.merge(new_dep).approved.should == false
    end
  end
end

