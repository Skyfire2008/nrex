import haxe.unit.TestRunner;

import nrex.core.Entity;

//import haxe.io.Bytes;

class TestMain{

	public static function main(){
		var runner=new TestRunner();

		runner.run();
	}

}

class HpGroup{
	public var hp: IntWrapper;
	public var maxHp: IntWrapper;
}

class PosGroup{
	public var x: Float;
	public var y: Float;
}

@has("HpGroup", "PosGroup", "haxe.io.Bytes")
class SimpleEntity extends Entity{

}



class IntWrapper{
	public var val: Int;

	public function new(val: Int){
		this.val=val;
	}
}