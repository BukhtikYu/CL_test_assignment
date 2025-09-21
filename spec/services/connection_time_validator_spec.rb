require 'rails_helper'

RSpec.describe ConnectionTimeValidator do
  describe '.valid?' do
    let(:arrival_time) { Time.zone.parse('2024-01-01 10:00:00') }
    let(:departure_time) { Time.zone.parse('2024-01-01 18:00:00') } # 8 hours later

    context 'with valid connection time' do
      it 'returns true for 8 hour connection' do
        expect(described_class.valid?(arrival_time, departure_time)).to be true
      end

      it 'returns true for 12 hour connection' do
        departure = arrival_time + 12.hours
        expect(described_class.valid?(arrival_time, departure)).to be true
      end

      it 'returns true for 48 hour connection' do
        departure = arrival_time + 48.hours
        expect(described_class.valid?(arrival_time, departure)).to be true
      end
    end

    context 'with invalid connection time' do
      it 'returns false for connection less than 8 hours' do
        departure = arrival_time + 7.hours
        expect(described_class.valid?(arrival_time, departure)).to be false
      end

      it 'returns false for connection more than 48 hours' do
        departure = arrival_time + 49.hours
        expect(described_class.valid?(arrival_time, departure)).to be false
      end

      it 'returns false when departure is before arrival' do
        departure = arrival_time - 1.hour
        expect(described_class.valid?(arrival_time, departure)).to be false
      end
    end

    context 'with nil values' do
      it 'returns false when arrival_time is nil' do
        expect(described_class.valid?(nil, departure_time)).to be false
      end

      it 'returns false when departure_time is nil' do
        expect(described_class.valid?(arrival_time, nil)).to be false
      end

      it 'returns false when both are nil' do
        expect(described_class.valid?(nil, nil)).to be false
      end
    end

    context 'with exact boundary times' do
      it 'returns true for exactly 8 hours' do
        departure = arrival_time + 8.hours
        expect(described_class.valid?(arrival_time, departure)).to be true
      end

      it 'returns true for exactly 48 hours' do
        departure = arrival_time + 48.hours
        expect(described_class.valid?(arrival_time, departure)).to be true
      end

      it 'returns false for just under 8 hours' do
        departure = arrival_time + 8.hours - 1.minute
        expect(described_class.valid?(arrival_time, departure)).to be false
      end

      it 'returns false for just over 48 hours' do
        departure = arrival_time + 48.hours + 1.minute
        expect(described_class.valid?(arrival_time, departure)).to be false
      end
    end
  end
end
