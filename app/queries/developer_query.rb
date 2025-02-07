class DeveloperQuery
  include Pagy::Backend

  alias_method :build_pagy, :pagy

  attr_reader :options

  def initialize(options = {})
    @options = options
    @sort = options.delete(:sort)
    @time_zones = options.delete(:time_zones)
  end

  def pagy
    @pagy ||= initialize_pagy.first
  end

  def records
    @records ||= initialize_pagy.last
  end

  def sort
    @sort.to_s.downcase.to_sym == :availability ? :availability : :newest
  end

  def time_zones
    @time_zones.to_a.reject(&:blank?)
  end

  private

  def initialize_pagy
    @_records = Developer.includes(:role_type).with_attached_avatar
    sort_records
    time_zone_filter_records
    @pagy, @records = build_pagy(@_records)
  end

  def sort_records
    if sort == :availability
      @_records.merge!(Developer.available_first)
    else
      @_records.merge!(Developer.newest_first)
    end
  end

  def time_zone_filter_records
    if utc_offsets.any?
      @_records.merge!(Developer.filter_by_utc_offset(utc_offsets))
    end
  end

  def utc_offsets
    time_zones.map { |tz| tz.to_f * SECONDS_IN_AN_HOUR }
  end

  # Needed for #pagy (aliased to #build_pagy) helper.
  def params
    options
  end
end
