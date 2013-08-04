require 'actv/tag'

module ACTV
  class AssetTag < Base
    def tag
      @tag ||= ACTV::Tag.fetch_or_create(@attrs[:tag]) unless @attrs[:tag].nil?
    end
  end
end