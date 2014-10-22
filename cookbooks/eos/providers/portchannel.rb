#
# Chef Cookbook   : eos
# File            : provider/portchannel.rb
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
  converge_by("create lag #{@new_resource.name}") do
    if !@current_resource.exists
      converge_by("lag #{@new_resource.name} will be created") do
        create_lag
      end
    else
      converge_by("edit lag #{@new_resource.name} will be modified") do
        edit_lag
      end
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by("remove lag #{@current_resource.name}") do
      execute "devops lag delete" do
        command "devops lag delete #{new_resource.name}"
      end
    end
  else
    Chef::Log.info("Lag #{new_resource.name} doesn't exist, nothing to delete")
  end
end

def load_current_resource
  Chef::Log.info "Loading current resource #{@new_resource.name}"
  @current_resource = Chef::Resource::EosPortchannel.new(@new_resource.name)
  @current_resource.exists = false

  if resource_exists?
    resp = run_command('devops lag list', jsonify=true)
    lag = resp['result'][@new_resource.name]
    @current_resource.links(lag['links'])
    @current_resource.minimum_links(lag['minimum_links'])
    @current_resource.lacp(lag['lacp'])
    @current_resource.exists = true

  else
    Chef::Log.info "Lag interface #{@new_resource.name} doesn't exist"
  end

end

def resource_exists?
  Chef::Log.info("Looking to see if lag #{@new_resource.name} exists")
  lags = run_command('devops lag list', jsonify=true)
  return lags['result'].has_key?(@new_resource.name)
end


def create_lag
  params = Array.new()
  (params << "--links" << new_resource.links.join(',')) if new_resource.links
  (params << "--minimum-links" << new_resource.minimum_links) if new_resource.minimum_links
  (params << "--lacp" << new_resource.lacp) if new_resource.lacp
  if !params.empty?
    execute "devops lag create" do
      command "devops lag create #{new_resource.name} #{params.join(' ')}"
    end
  end
end

def edit_lag
  params = Array.new()
  (params << "--links" << new_resource.links.join(',')) if has_changed?(current_resource.links, new_resource.links)
  (params << "--minimum-links" << new_resource.minimum_links) if has_changed?(current_resource.minimum_links, new_resource.minimum_links)
  (params << "--lacp" << new_resource.lacp) if has_changed?(current_resource.lacp, new_resource.lacp)
  if !params.empty?
    execute "devops lag edit" do
      Chef::Log.debug("devops lag edit #{new_resource.name} #{params.join(' ')}")
      command "devops lag edit #{new_resource.name} #{params.join(' ')}"
    end
  end
end


