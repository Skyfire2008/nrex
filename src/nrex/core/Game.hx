package nrex.core;

//TODO: add metadata to add systems by their name and not location
@:autoBuild(nrex.core.Macro.buildGame())
class Game{

	public function new(){
		
	}
	
	/**
	 * Updates the game state, will be overriden by macro
	 */
	public function update(){
		throw "Update method is not implemented";
	}

}