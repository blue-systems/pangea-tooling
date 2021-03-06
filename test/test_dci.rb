# frozen_string_literal: true
require_relative 'lib/testcase'

require_relative '../lib/dci'

class DCITest < TestCase
  def assert_equal_collection(expected, actual)
    assert_equal(expected.sort, actual.sort)
  end

  def test_release_types
    assert_equal(%w[desktop core zeronet], DCI.release_types)
  end

  def test_architectures
    assert_equal_collection(%w[amd64], DCI.architectures)
  end

  def test_extra_architectures
    assert_equal_collection(%w[armhf arm64], DCI.extra_architectures)
  end

  def test_all_architectures
    assert_equal_collection(%w[amd64 armhf arm64], DCI.all_architectures)
  end

  def test_series
    assert_equal_collection(%w[2101 next], DCI.series.keys)
    assert_equal_collection(%w[20201123 20210414], DCI.series.values)
    assert_equal('20201123', DCI.series['2101'])
    assert_equal('20210414', DCI.series['next'])

    # With sorting
    assert_equal('2101', DCI.series(sort: :ascending).keys.first)
  end

  def test_latest_series
    assert_equal('next', DCI.latest_series)
  end

  def test_releases_for_type
    assert_equal( ['netrunner-desktop'], DCI.releases_for_type('desktop'))
    assert_is_a(DCI.releases_for_type('desktop'), Array)
  end

  def test_release_data_for_type
    assert_equal({"netrunner-core"=>
  {"arch"=>"amd64",
   "components"=>"netrunner extras artwork common backports netrunner-core"},
 "netrunner-core-c1"=>
  {"arch"=>"armhf",
   "components"=>
    "netrunner extras artwork common backports c1 netrunner-core"}}, DCI.release_data_for_type('core'))
  end

  def test_get_release_data
    release_data = DCI.get_release_data('desktop', 'netrunner-desktop')
    assert_is_a(release_data, Hash)
    assert_equal({
      "arch"=>"amd64",
      "components"=>
      "netrunner extras artwork common backports netrunner-core netrunner-desktop"
                          }, release_data)
    assert_equal('amd64', release_data['arch'])
    assert_equal('netrunner extras artwork common backports netrunner-core netrunner-desktop', release_data['components'])
  end

  def test_arm_board_by_release
    assert_equal('c1', DCI.arm_board_by_release('netrunner-core-c1'))
  end

  def test_arm_boards
    assert_equal(%w[c1 rock64], DCI.arm_boards)
  end
  
  def test_arm
    assert_equal(true, DCI.arm?('netrunner-core-c1'))
  end
end
