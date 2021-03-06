describe KnapsackPro::Allocator do
  let(:test_files) { double }
  let(:ci_node_total) { double }
  let(:ci_node_index) { double }
  let(:repository_adapter) { instance_double(KnapsackPro::RepositoryAdapters::EnvAdapter, commit_hash: double, branch: double) }

  let(:allocator) do
    described_class.new(
      test_files: test_files,
      ci_node_total: ci_node_total,
      ci_node_index: ci_node_index,
      repository_adapter: repository_adapter
    )
  end

  describe '#test_file_paths' do
    let(:response) { double }

    subject { allocator.test_file_paths }

    before do
      action = double
      expect(KnapsackPro::Client::API::V1::BuildDistributions).to receive(:subset).with({
        commit_hash: repository_adapter.commit_hash,
        branch: repository_adapter.branch,
        node_total: ci_node_total,
        node_index: ci_node_index,
        test_files: test_files,
      }).and_return(action)

      connection = instance_double(KnapsackPro::Client::Connection,
                                   call: response,
                                   success?: success?,
                                   errors?: errors?)
      expect(KnapsackPro::Client::Connection).to receive(:new).with(action).and_return(connection)
    end

    context 'when successful request to API' do
      let(:success?) { true }

      context 'when response has errors' do
        let(:errors?) { true }

        it do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when response has no errors' do
        let(:errors?) { false }
        let(:response) do
          {
            'test_files' => [
              { 'path' => 'a_spec.rb' },
              { 'path' => 'b_spec.rb' },
            ]
          }
        end

        it { should eq ['a_spec.rb', 'b_spec.rb'] }
      end
    end

    context 'when not successful request to API' do
      let(:success?) { false }
      let(:errors?) { false }

      before do
        test_flat_distributor = instance_double(KnapsackPro::TestFlatDistributor)
        expect(KnapsackPro::TestFlatDistributor).to receive(:new).with(test_files, ci_node_total).and_return(test_flat_distributor)
        expect(test_flat_distributor).to receive(:test_files_for_node).with(ci_node_index).and_return([
          { 'path' => 'c_spec.rb' },
          { 'path' => 'd_spec.rb' },
        ])
      end

      it { should eq ['c_spec.rb', 'd_spec.rb'] }
    end
  end
end
