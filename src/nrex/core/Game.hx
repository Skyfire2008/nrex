package nrex.core;

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