# frozen_string_literal: true

describe Que::View do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '#fetch_dashboard_stats' do
    before do
      create :que_job
      create :que_job, :failing
      create :que_job, :finished
      create :que_job, :expired
    end

    it 'returns dashboard stats' do
      expect(described_class.fetch_dashboard_stats[0]).to include(
        {
          total: 4,
          running: 0,
          scheduled: 1,
          failing: 1,
          finished: 1,
          expired: 1
        }
      )
    end
  end

  describe '#fetch_queue_metrics' do
    before do
      create :que_job
      create :que_job, :failing
      create :que_job, :finished
      create :que_job, :expired
    end

    it 'returns dashboard stats', :aggregate_failures do
      result = described_class.fetch_queue_metrics

      expect(result.keys).to eq [:default]
      expect(result[:default]).to include(
        {
          running: 0,
          scheduled: 1,
          failing: 1,
          finished: 1,
          expired: 1
        }
      )
    end
  end

  describe '#reschedule_jobs_by_ids' do
    let!(:job1) { create :que_job }
    let!(:job2) { create :que_job }
    let!(:job3) { create :que_job }

    it 'reschedules only specified jobs', :aggregate_failures do
      original_job3_run_at = job3.run_at
      time = Time.current
      described_class.reschedule_jobs_by_ids([job1.id, job2.id], time)

      expect(job1.reload.run_at).to be_within(1.second).of(time)
      expect(job2.reload.run_at).to be_within(1.second).of(time)
      expect(job3.reload.run_at).to eq(original_job3_run_at)
    end

    it 'returns empty array when no job IDs provided' do
      result = described_class.reschedule_jobs_by_ids([], Time.current)
      expect(result).to eq []
    end

    it 'returns empty array when nil job IDs provided' do
      result = described_class.reschedule_jobs_by_ids(nil, Time.current)
      expect(result).to eq []
    end
  end

  describe '#delete_jobs_by_ids' do
    let!(:job1) { create :que_job }
    let!(:job2) { create :que_job }
    let!(:job3) { create :que_job }

    it 'deletes only specified jobs', :aggregate_failures do
      described_class.delete_jobs_by_ids([job1.id, job2.id])

      expect(QueJob.exists?(job1.id)).to be false
      expect(QueJob.exists?(job2.id)).to be false
      expect(QueJob.exists?(job3.id)).to be true
    end

    it 'returns empty array when no job IDs provided' do
      result = described_class.delete_jobs_by_ids([])
      expect(result).to eq []
    end

    it 'returns empty array when nil job IDs provided' do
      result = described_class.delete_jobs_by_ids(nil)
      expect(result).to eq []
    end
  end
end
