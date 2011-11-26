require 'bundler/setup'

require File.expand_path(File.dirname(__FILE__) + '/../gmail_leads_stats')

require 'minitest/autorun'

describe GmailAnalytics::DataAnalysis do

  it "must calculate thread_ids_counters" do
    thread_ids = %w[ a 1 1 x a _ x 1 a a a ]
    output = GmailAnalytics::DataAnalysis.thread_ids_counters thread_ids
    output.must_equal 'a' => 5, '1' => 3, 'x' => 2, '_' => 1 
  end

  it "must calculate thread_length_stats" do
    thread_ids_counters = { 'a' => 5, 'b' => 3, '1' => 3, 'x' => 2, '_' => 1 }
    output = GmailAnalytics::DataAnalysis.thread_length_stats thread_ids_counters 
    output.must_equal [nil, 1, 1, 2, nil, 1]
  end

  it "must calculate four steps stats" do
    thread_length_stats = [nil, 5, 4, 2, 1, nil, 1]
    output = GmailAnalytics::DataAnalysis.four_steps_stats thread_length_stats
    output.must_equal [13, 8, 4, 2]
  end

  describe "run" do

    before do
      @thread_ids = %w[ a 1 1 x a _ x 1 a a a ]
    end

    it "must return collection of two elements" do
      output = GmailAnalytics::DataAnalysis.generate_thread_stats @thread_ids
      output.length.must_equal 2
    end

    it "must return thread length stats" do
      output = GmailAnalytics::DataAnalysis.generate_thread_stats @thread_ids
      stats = output[1]
      stats.must_equal [nil, 1, 1, 1, nil, 1]
    end

    it "must return four steps stats" do
      output = GmailAnalytics::DataAnalysis.generate_thread_stats @thread_ids
      stats = output[0]
      stats.must_equal [4, 3, 2, 1]
    end

  end

end
