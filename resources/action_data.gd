class_name ActionData
extends Resource

@export var action : Globals.ActionTypes
@export var time_cost : float = 1.0
@export var try_message : String
@export var resource_cost : Array[ResourceQuantity]
@export var success_message : String
@export var success_resource_result : Array[ResourceQuantity]
@export var location_success_resource_result : Array[ResourceQuantity]
@export var failure_message : String
@export var failure_resource_result : Array[ResourceQuantity]
@export var location_failure_resource_result : Array[ResourceQuantity]
