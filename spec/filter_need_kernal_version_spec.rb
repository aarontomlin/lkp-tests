require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require "#{LKP_SRC}/lib/job"

describe 'filter/need_kernel_version.rb' do
  before(:each) do
    @tmp_dir = Dir.mktmpdir(nil, '/tmp')
    FileUtils.touch "#{@tmp_dir}/vmlinuz"
    FileUtils.chmod 'go+rwx', @tmp_dir
  end

  after(:each) do
    FileUtils.remove_entry @tmp_dir
  end

  def generate_context(kernel_version)
    File.open(File.join(@tmp_dir, 'context.yaml'), 'w') do |f|
      f.write({ 'rc_tag' => kernel_version }.to_yaml)
    end
  end

  def generate_job(contents = "\n")
    job_file = "#{@tmp_dir}/job.yaml"

    File.open(job_file, 'w') do |f|
      f.puts contents
      f.puts "kernel: #{@tmp_dir}/vmlinuz"
    end

    # Job.open can filter comments (e.g. # support kernel xxx)
    Job.open(job_file)
  end

  context 'kernel is not satisfied' do
    it 'filters the job' do
      generate_context('v4.16')
      job = generate_job <<~EOF
              need_kernel_version: '>= v4.17'
      EOF
      expect { job.expand_params }.to raise_error Job::ParamError
    end
  end

  context 'kernel is satisfied' do
    it 'does not filters the job' do
      generate_context('v5.0')
      job = generate_job <<~EOF
              need_kernel_version: '>= v4.17'
      EOF
      job.expand_params
    end
  end
end
