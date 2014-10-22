#
# Chef Cookbook   : eos
# File            : provider/switchport.rb
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
  converge_by("manage will create switchport #{@new_resource.name}") do
    if !@current_resource.exists
      converge_by("L2interface #{@new_resource.name} will be created") do
        create_switchport
      end
    else
      converge_by("manage will modify switchport #{@new_resource.name}") do
        edit_switchport
      end
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by("remove l2interface #{@current_resource.name}") do
      execute "devops switchport delete" do
        Chef::Log.debug "Command: devops switchport delete #{new_resource.name}"
        command "devops switchport delete #{new_resource.name}"
      end
    end
  else
    Chef::Log.info("L2interface doesn't exist, nothing to delete")
  end
end

def load_current_resource
  Chef::Log.info "Loading current resource #{@new_resource.name}"
  @current_resource = Chef::Resource::EosSwitchport.new(@new_resource.name)
  @current_resource.exists = false

  if resource_exists?
    resp = run_command('devops switchport list', jsonify=true)
    interface = resp['result'][@new_resource.name]
    @current_resource.untagged_vlan(interface['untagged_vlan'])
    @current_resource.tagged_vlans(interface['tagged_vlans'])
    @current_resource.vlan_tagging(interface['vlan_tagging'])
    @current_resource.exists = true

  else
    Chef::Log.info "L2 interface #{@new_resource.name} doesn't exist"
  end

end

def resource_exists?
  Chef::Log.info("Looking to see if l2interface #{@new_resource.name} exists")
  resp = run_command('devops switchport list', jsonify=true)
  return resp['result'].has_key?(@new_resource.name)
end


def create_switchport
  params = Array.new()
  (params << "--untagged-vlan" << new_resource.untagged_vlan) if new_resource.untagged_vlan
  (params << "--tagged-vlans" << new_resource.tagged_vlans.join(',')) if new_resource.tagged_vlans
  (params << "--vlan-tagging" << new_resource.vlan_tagging) if new_resource.vlan_tagging
  if !params.empty?
    execute "devops switchport create" do
      Chef::Log.debug "Command: devops switchport create #{new_resource.name} #{params.join(' ')}"
      command "devops switchport create #{new_resource.name} #{params.join(' ')}"
    end
  end
end

def edit_switchport
  params = Array.new()
  (params << "--untagged-vlan" << new_resource.untagged_vlan) if has_changed?(current_resource.untagged_vlan, new_resource.untagged_vlan)
  (params << "--tagged-vlans" << new_resource.tagged_vlans.join(',')) if has_changed?(current_resource.tagged_vlans, new_resource.tagged_vlans)
  (params << "--vlan-tagging" << new_resource.vlan_tagging) if has_changed?(current_resource.vlan_tagging, new_resource.vlan_tagging)
  if !params.empty?
    execute "devops switchport edit" do
      Chef::Log.debug "Command: devops switchport edit #{new_resource.name} #{params.join(' ')}"
      command "devops switchport edit #{new_resource.name} #{params.join(' ')}"
    end
  end
end


