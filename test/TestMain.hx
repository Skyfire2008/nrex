import haxe.unit.TestRunner;
import haxe.unit.TestCase;

import nrex.core.Entity;
import nrex.core.Group;
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

class HpGroup extends Group{
	public var hp: IntWrapper;
	public var maxHp: IntWrapper;

	public function new(owner: Entity, maxHp: IntWrapper){
		super(owner);
		this.maxHp=maxHp;
		this.hp=maxHp;
	}
}

class PosGroup extends Group{
	public var x: IntWrapper;
	public var y: IntWrapper;
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