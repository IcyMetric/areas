#!/usr/bin/ruby
require 'cfpropertylist'
require 'yaml'
require 'pp'

def data_from_file( file )
  plist = CFPropertyList::List.new(:file => file )
  CFPropertyList.native_types(plist.value )
end
  
base = 'static-cdn.crimecitygame.com/ccios/plist'
version = ARGV.first

areas = data_from_file "#{ base }/#{ version }/area.plist"
area_buildings = data_from_file "#{ base }/#{ version }/area_building.plist"
area_mastery_rewards = data_from_file "#{ base }/#{ version }/area_mastery_reward.plist"
bosses = data_from_file "#{ base }/#{ version }/boss.plist"
buildings = data_from_file "#{ base }/#{ version }/building.plist"
items = data_from_file "#{ base }/#{ version }/item.plist"
jobs = data_from_file "#{ base }/#{ version }/job.plist" 
job_reqs = data_from_file "#{ base }/#{ version }/job_req.plist" 
loot_group_locations = data_from_file "#{ base }/#{ version }/loot_group_location.plist"
loots = data_from_file "#{ base }/#{ version }/loot.plist"
npcs = data_from_file "#{ base }/#{ version }/npc.plist"

areas.each do |area|
  next if area['area_type'] != 'npc'
  if ! Dir.exists? "output/#{ area[ 'name' ] }"
    Dir.mkdir( "output/#{ area[ 'name' ] }" )
  end

  area_meta = Hash.new
  area_jobs = Array.new
  area_meta[ 'name' ] = area[ 'name' ].force_encoding("UTF-8")
  area_meta[ 'unlock_level' ] = area[ 'unlock_level' ]
  area_meta[ 'is_available' ] = area[ 'is_available' ]
  area_meta[ 'is_coming_soon' ] = area[ 'is_coming_soon' ]
  area_meta[ 'mastery rewards' ] = Array.new

  area_mastery_rewards.select{ |amr| amr[ 'area_id' ] == area[ 'id' ] }.each do |area_mastery_reward|
    amr_meta = Hash.new
    amr_meta[ 'level' ] = area_mastery_reward[ 'mastery_level' ]
    amr_meta[ 'exp' ] = area_mastery_reward[ 'area_mastery_exp_reward' ]
    if area_mastery_reward[ 'area_mastery_skill_point_reward' ] > 0
        amr_meta[ 'skill points' ] = area_mastery_reward[ 'area_mastery_skill_point_reward' ]
    elsif area_mastery_reward[ 'area_mastery_gold_reward' ] > 0
        amr_meta[ 'gold' ] = area_mastery_reward[ 'area_mastery_gold_reward' ]
    elsif area_mastery_reward[ 'area_mastery_money_reward' ] > 0
        amr_meta[ 'money' ] = area_mastery_reward[ 'area_mastery_money_reward' ]
    elsif area_mastery_reward[ 'area_mastery_respect_reward' ] > 0
        amr_meta[ 'respect' ] = area_mastery_reward[ 'area_mastery_respect_reward' ]
    elsif area_mastery_reward[ 'area_mastery_reward_type' ] == 'item'
        item = items.select{ |i| i['id'] == area_mastery_reward[ 'area_mastery_reward_id' ] }.first
        amr_meta[ 'item' ] = item[ 'name' ].force_encoding("UTF-8")
        amr_meta[ 'item attack' ] = item[ 'attack' ]
        amr_meta[ 'item defense' ] = item[ 'defense' ]
    elsif area_mastery_reward[ 'area_mastery_reward_type' ] == 'mafia'
        amr_meta[ 'mafia' ] = area_mastery_reward[ 'area_mastery_reward_quantity' ]
    end

    area_meta[ 'mastery rewards' ].push amr_meta
  end

  File.open( "output/#{ area[ 'name' ] }/meta.yaml", 'w' ){ |file| file.write YAML.dump area_meta }

  jobs.select{|j| j[ 'area_id' ] == area[ 'id' ] }.each do |job|
    job_loot_meta = Array.new
    job_meta = Hash.new
    if job[ 'target_type' ] == 'NPC'
        npc = npcs.select{ |n| n[ 'id' ] == job[ 'target_id' ] }.last
        job_meta[ 'target' ] = npc[ 'name' ].force_encoding("UTF-8")
    elsif job[ 'target_type' ] == 'building'
        area_building = area_buildings.select{ |ab| ab[ 'id' ] == job[ 'target_id' ] }.last
        if area_building.nil?
            next
        end
        building = buildings.select{ |b| b[ 'id' ] == area_building[ 'building_id' ] }.first
        job_meta[ 'target' ] = building[ 'name' ].force_encoding("UTF-8")
    end
    job_meta[ 'job' ] = job[ 'name' ].force_encoding("UTF-8")
    job_meta[ 'energy' ] = job[ 'energy_required' ]
    job_meta[ 'exp' ] = job[ 'exp_payout' ]
    job_meta[ 'money max' ] = job[ 'money_payout_max' ]
    job_meta[ 'money min' ] = job[ 'money_payout_min' ]
    if job.key? 'boss_id'
        boss = bosses.select{ |b| b[ 'id' ] == job[ 'boss_id' ] }.first
        job_meta[ 'clicks needed' ] = boss[ 'num_clicks' ]
        job_meta[ 'money max' ] = boss[ 'money_payout_max' ]
        job_meta[ 'money min' ] = boss[ 'money_payout_min' ]
        if boss[ 'loot_list' ] != '[]'
            boss[ 'loot_list' ].split( '], [' ).each{ |x| x.gsub!(/(\[|\])/, '') }.each do |combined|
              loot_meta = Hash.new
              ( item_id, percent ) = combined.split ', '
              item = items.select{ |i| i[ 'id' ] == item_id.to_i }.first
              loot_meta[ 'name' ] = item[ 'name' ].force_encoding("UTF-8")
              loot_meta[ 'type' ] = item[ 'type' ].force_encoding("UTF-8")
              loot_meta[ 'percent' ] = percent.to_f
              loot_meta[ 'attack' ] = item[ 'attack' ]
              loot_meta[ 'defense' ] = item[ 'defense' ]
              loot_meta[ 'energy for 1' ] = ( job_meta[ 'energy' ] * job_meta[ 'clicks needed' ] ) / loot_meta[ 'percent' ]
              loot_meta[ 'exp for 1' ] = ( job_meta[ 'exp' ] * job_meta[ 'clicks needed' ] ) / loot_meta[ 'percent' ]
              loot_meta[ 'attack for energy' ] = loot_meta[ 'attack' ] / loot_meta[ 'energy for 1' ]
              loot_meta[ 'defense for energy' ] = loot_meta[ 'defense' ] / loot_meta[ 'energy for 1' ]
              loot_meta[ 'attack for exp' ] = loot_meta[ 'attack' ] /  loot_meta[ 'exp for 1' ]
              loot_meta[ 'defense for exp' ] = loot_meta[ 'defense' ] / loot_meta[ 'exp for 1' ]
              job_loot_meta.push loot_meta
            end
        end
    else
        job_meta[ 'clicks needed' ] = 1
    end
    job_meta[ 'total energy' ] = job_meta[ 'energy' ] * job_meta[ 'clicks needed' ]
    job_meta[ 'total exp' ] = job_meta[ 'exp' ] * job_meta[ 'clicks needed' ]
    job_meta[ 'average money per energy' ] = ( ( job_meta[ 'money max' ] + job_meta[ 'money min' ] ) / 2 ) / job_meta[ 'total energy' ]
    job_meta[ 'average money per exp' ] = ( ( job_meta[ 'money max' ] + job_meta[ 'money min' ] ) / 2 ) / job_meta[ 'total exp' ]
    if job[ 'loot_drop_chance' ] != "0.0"
      loot_group_location = loot_group_locations.select{ |lgl| lgl[ 'action_type' ] == 'job' and lgl['source_id'] == job[ 'id' ] }.first
      if !loot_group_location.nil? and loot_group_location.key?'loot_group_id'
        loot = loots.select{ |l| l[ 'loot_group_id' ] == loot_group_location[ 'loot_group_id' ] }.first
        if !loot.nil? and loot[ 'loot_type' ] == 'item'
          item = items.select{ |i| i[ 'id' ] == loot[ 'loot_id' ] }.first
          if !item.nil?
              loot_meta = Hash.new
              loot_meta[ 'name' ] = item[ 'name' ].force_encoding("UTF-8")
              loot_meta[ 'type' ] = item[ 'type' ].force_encoding("UTF-8")
              loot_meta[ 'percent' ] = job[ 'loot_drop_chance' ].to_f
              loot_meta[ 'attack' ] = item[ 'attack' ]
              loot_meta[ 'defense' ] = item[ 'defense' ]
              loot_meta[ 'energy for 1' ] = ( job_meta[ 'energy' ] * job_meta[ 'clicks needed' ] ) / loot_meta[ 'percent' ]
              loot_meta[ 'exp for 1' ] = ( job_meta[ 'exp' ] * job_meta[ 'clicks needed' ] ) / loot_meta[ 'percent' ]
              loot_meta[ 'attack for energy' ] = loot_meta[ 'attack' ] / loot_meta[ 'energy for 1' ]
              loot_meta[ 'defense for energy' ] = loot_meta[ 'defense' ] / loot_meta[ 'energy for 1' ]
              loot_meta[ 'attack for exp' ] = loot_meta[ 'attack' ] /  loot_meta[ 'exp for 1' ]
              loot_meta[ 'defense for exp' ] = loot_meta[ 'defense' ] / loot_meta[ 'exp for 1' ]
              job_loot_meta.push loot_meta
          end
        end
      end
      job_meta[ 'loot' ] = job_loot_meta
      area_jobs.push job_meta
    end
    File.open( "output/#{ area[ 'name' ] }/jobs.yaml", 'w' ){ |file| file.write YAML.dump area_jobs }
  end
end

