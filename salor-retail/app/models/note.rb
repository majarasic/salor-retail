# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Note < ActiveRecord::Base
	include SalorScope
  include SalorModel
  belongs_to :notable, :polymorphic => true
end
