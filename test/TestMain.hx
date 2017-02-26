import haxe.unit.TestRunner;
import haxe.unit.TestCase;

import nrex.core.Entity;

import nrex.core.Macro;

//import haxe.io.Bytes;

class TestMain{

	public static function main(){
		var runner=new TestRunner();

		runner.add(new TestMakeVarName());
		runner.add(new TestAddingFieldsForGroups());

		runner.run();
	}

}

class TestMakeVarName extends TestCase{

	public function testShortName(){
		assertEquals("hpGroup", Macro.makeVarName("HpGroup"));
	}

	public function testLongName(){
		assertEquals("nrexGroupsHpGroup", Macro.makeVarName("nrex.groups.HpGroup"));
	}

}

class TestAddingFieldsForGroups extends TestCase{

	public function testHasFields(){
		var e: SimpleEntity=new SimpleEntity();
		try{
			var foo=e.hpGroup;
			var bar=e.posGroup;
			var baz=e.haxeIoBytes;
			assertTrue(true);
		}catch(e: Dynamic){
			trace(e);
			assertTrue(false);
		}
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