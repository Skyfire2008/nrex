package nrex.core;

@:build(nrex.core.Macro.buildGame())
@:systemLocation("test")
class Game{

	public function new(){
		
	}
	
	/**
	 * Updates the game state, will be filled by macro
	 */
	public function update(){
		throw "Update method is not implemented";
	}

}