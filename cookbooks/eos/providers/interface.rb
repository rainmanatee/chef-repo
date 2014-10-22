#
# Chef Cookbook   : eos
# File            : provider/interface.rb
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
  converge_by("manage interface #{new_resource.name}") do
    params = Array.new()
    (params << "--admin" << new_resource.admin) if has_changed?(current_resource.admin, new_resource.admin)
    (params << "--description" << %Q{"#{new_resource.description}"}) if has_changed?(current_resource.description, new_resource.description)

    if !params.empty?
      execute "devops interface edit" do
        Chef::Log.debug "Command: devops interface edit #{new_resource.name} #{params.join(' ')}"
        command "devops interface edit #{new_resource.name} #{params.join(' ')}"
      end
    else
      Chef::Log.info "No attributes have changed"
    end
  end
end

action :default do
  converge_by("remove interface #{new_resource.name}") do
    execute "devops interface delete" do
      command "devops interface delete #{new_resource.name}"
    end
  end
end

def load_current_resource
  Chef::Log.info "Loading current resource #{@new_resource.name}"

  resp = run_command("devops interface list", jsonify=true)
  if !resp['result'].nil?
    interface = resp['result'][@new_resource.name]

    @current_resource = Chef::Resource::EosInterface.new(@new_resource.name)
    @current_resource.admin(interface['admin'])
    @current_resource.description(interface['description'])
    @current_resource.exists = true

  else
    Chef::Log.fatal "Unable to load current resource"

  end

end


