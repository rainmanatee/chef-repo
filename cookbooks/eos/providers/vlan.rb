#
# Chef Cookbook   : eos
# File            : provider/vlan.rb
#
# Copyright (c) 2013, Arista Networks
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
#   Neither the name of the {organization} nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

def whyrun_supported?
  true
end

action :manage do
  converge_by("manage will create vlan #{@new_resource.name}") do
    if !@current_resource.exists
      converge_by("Vlan #{@new_resource.name} will be created") do
        create_vlan
      end
    else
      converge_by("manage will edit vlan #{@new_resource.name}") do
        edit_vlan
      end
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by("remove vlan #{@current_resource.name}") do
      execute "devops vlan delete" do
        Chef::Log.debug "Command: devops vlan delete #{new_resource.vlan_id}"
        command "devops vlan delete #{new_resource.vlan_id}"
      end
    end
  else
    Chef::Log.info("Vlan doesn't exist, nothing to delete")
  end
end

def load_current_resource
  Chef::Log.info "Loading current resource #{@new_resource.name}"
  @current_resource = Chef::Resource::EosVlan.new(@new_resource.name)
  @current_resource.vlan_id(@new_resource.vlan_id)
  @current_resource.exists = false

  if resource_exists?
    resp = run_command('devops vlan list', jsonify=true)
    vlan = resp['result'][@current_resource.vlan_id]
    @current_resource.vlan_id(vlan['vlan_id'])
    @current_resource.exists = true

  else
    Chef::Log.info "Vlan #{@new_resource.name} (#{@new_resource.vlan_id}) doesn't exist"
  end

end

def resource_exists?
  Chef::Log.info("Looking to see if vlan #{@new_resource.name} (#{@new_resource.vlan_id}) exists")
  resp = run_command('devops vlan list', jsonify=true)
  return resp['result'].has_key?(@new_resource.vlan_id)
end

def create_vlan
  execute "devops vlan create" do
    params = []
    params << "--name" << new_resource.name
    command "devops vlan create #{new_resource.vlan_id} #{params.join(' ')}"
  end
end

def edit_vlan
  params = []
  (params << "--name" << new_resource.name) if has_changed?(current_resource.name, new_resource.name)
  if !params.empty?
    execute "devops vlan edit" do
      Chef::Log.debug "Command: devops vlan edit #{new_resource.vlan_id} #{params.join(' ')}"
      command "devops vlan edit #{new_resource.vlan_id} #{params.join(' ')}"
    end
  else
    Chef::Log.info "No attributes have changed"
  end
end


