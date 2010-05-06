require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/module/delegation
  active_support/core_ext/hash/keys
  active_support/core_ext/hash/slice
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3
require 'remote_table'
require 'erratum'
require 'erratum/delete'
require 'erratum/reject'
require 'erratum/replace'
require 'erratum/simplify'
require 'erratum/transform'
require 'erratum/truncate'

class Errata
  ERRATUM_TYPES = %w{delete replace simplify transform truncate}

  attr_reader :klass
  
  def initialize(options = {})
    @klass = options[:klass]
    @_table = RemoteTable.new(:url => options[:url])
  end
  
  def rejects?(row)
    rejections.any? { |erratum| erratum.targets?(row) }
  end
  
  def correct!(row)
    corrections.each { |erratum| erratum.correct!(row) }
    nil
  end
  
  def implied_matching_methods
    (rejections + corrections).map { |erratum| erratum.matching_method }.compact.uniq
  end
  
  def rejections
    @_rejections ||= @_table.rows.map { |hash| hash.symbolize_keys!; ::Errata::Erratum::Reject.new(self, hash) if hash[:action] == 'reject' }.compact
  end
  
  def corrections
    @_corrections ||= @_table.rows.map { |hash| hash.symbolize_keys!; "::Errata::Erratum::#{hash[:action].camelcase}".constantize.new(self, hash) if ERRATUM_TYPES.include?(hash[:action]) }.compact
  end
end
