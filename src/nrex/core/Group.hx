package nrex.core;

/**
 * Groups group together several components, required by systems
 */
@:autoBuild(nrex.core.Macro.buildGroup())
class Group{
	//TODO: add a metadata, that tells macro not to add a field to entity if entity has a group
	public var owner: Entity;

	public function new(owner: Entity){
		this.owner=owner;
	}
}