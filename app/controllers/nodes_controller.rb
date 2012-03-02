require 'yaml'
YAML::ENGINE.yamler = 'syck'
class NodesController < ApplicationController
  include SalorBase
  # GET /nodes
  # GET /nodes.xml
  before_filter :authify, :except => [:receive]
  before_filter :initialize_instance_variables, :except => [:receive]
  def send_msg
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    node = Cue.find_by_id params[:id]
    if node then
      url = URI.parse(node.url)
      req.body = node.payload
      log_action "Sending Single MSG #{node.id}"
      req2 = Net::HTTP.new(url.host, url.port)
      response = req2.start {|http| http.request(req) }
      response_parse = JSON.parse(response.body)
      log_action("Received From Node: " + response.body)
      node.update_attribute :is_handled, true
    end
    redirect_to request.referer
  end

  def receive_msg
    msg = Cue.find_by_id params[:id]
    p = SalorBase.stringify_keys(JSON.parse(msg.payload))
    @node = Node.where(:sku => p[:node][:sku]).first
    if @node then
      @node.handle(p)
    end
    redirect_to request.referer
  end
  def index
    @nodes = Node.scopied

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nodes }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    @node = Node.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.xml
  def new
    @node = Node.scopied.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.scopied.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.xml
  def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        @node.broadcast_add_me
        format.html { redirect_to(@node, :notice => 'Node was successfully created.') }
        format.xml  { render :xml => @node, :status => :created, :location => @node }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.xml
  def update
    @node = Node.scopied.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html { redirect_to(@node, :notice => 'Node was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.xml
  def destroy
    @node = Node.scopied.find(params[:id])
    @node.kill

    respond_to do |format|
      format.html { redirect_to(nodes_url) }
      format.xml  { head :ok }
    end
  end
  def receive
    begin
    SalorBase.log_action("NodesController","Starting Receive action")
    if params[:node] then
      SalorBase.log_action("NodesController","looking for node")
      @node = Node.where(:sku => params[:node][:sku]).first
      if @node then
        SalorBase.log_action("NodesController","node found, handling")
        n = Cue.new(:source_sku =>params[:node][:sku], :destination_sku => params[:target][:sku],:to_receive => true, :payload => request.body.read)
        n.save
        #render :json => @node.handle(SalorBase.symbolize_keys(JSON.parse(request.body.read))).to_json and return
        render :json => {:success => true}.to_json and return
      else
        SalorBase.log_action("NodesController","Node #{params[:node][:sku]} Could Not Be Found")
        render :json => {:error => "Node could not be found"}.to_json
      end
    else
      SalorBase.log_action("NodesController","no node specified")
      render :json => {:error => "No Node"}.to_json
    end
    rescue => e
      render :text => "Error:" + e.message + e.backtrace.join("\n")
    end
  end
end
