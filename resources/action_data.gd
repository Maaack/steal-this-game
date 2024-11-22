class_name ActionData
extends Resource

@export var action : Globals.ActionTypes
@export var time_cost : int 
@export var try_message : String
@export var resource_cost : Array[ResourceQuantity]
@export var success_message : String
@export var success_resource_result : Array[ResourceQuantity]
@export var location_success_resource_result : Array[ResourceQuantity]
