require 'spec_helper'

describe ACTV::Client do

  before do
    @client = ACTV::Client.new
  end

  describe "#asset" do
    context "with a valid asset ID passed" do
      before do
        stub_get("/v2/assets/valid_asset.json").
        to_return(body: fixture("valid_asset.json"), headers: { content_type: "application/json; charset=utf-8" })
      end

      it "requests the correct asset" do
        @client.asset("valid_asset")
        a_get("/v2/assets/valid_asset.json").should have_been_made
      end

      it "returns the correct place" do
        asset = @client.asset("valid_asset")
        asset.place.name.should eq 'Kingwood Park New Jersey'
      end

      it "returns the correct description" do
        asset = @client.asset("valid_asset")
        asset.descriptions.size.should eq 1
        asset.descriptions.first.description.should eq 'The Run Daddy Run Event is the HCM Foundation way to bring the community together on Fathers Day Weekend to celebrate Fathers and their families.  100% of the proceeds will go to HCM service & scholarship programs.'
      end

      it "returns the correct status" do
        asset = @client.asset("valid_asset")
        asset.status.name.should eq 'VISIBLE'
      end

      it "returns the correct legacy data" do
        asset = @client.asset("valid_asset")
        asset.legacy_data.online_registration?.should eq "true"
      end

      it "return the correct asset channel" do
        asset = @client.asset("valid_asset")
        asset.asset_channels.size.should eq 2
        asset.asset_channels.first.sequence.should eq "1"
      end
    end
  end

end