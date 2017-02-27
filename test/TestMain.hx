import haxe.unit.TestRunner;
import haxe.unit.TestCase;

import nrex.core.Entity;
import nrex.core.Group;
import nrex.core.Macro;

/**
 * Test class
 * Kind of pointless to test macros, but oh well
 */
class TestMain{

	public static function main(){
		var runner=new TestRunner();

		runner.add(new TestMakeVarName());
		runner.add(new TestAddingFieldsForGroups());
		runner.add(new TestAddingConstructorsToGroups());

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

class TestAddingConstructorsToGroups extends TestCase{

	public function testCanCallConstructor(){
		try{
			var p: PosGroup=new PosGroup(null, null, null);
			assertTrue(true);
		}catch(e: Dynamic){
			trace(e);
			assertTrue(false);
		}
	}

	public function testConstructorSetsValues(){
		var e: Entity=new Entity();
		var p: PosGroup=new PosGroup(e, new IntWrapper(10), new IntWrapper(11));

		assertTrue(e.equals(p.owner));
		assertEquals(p.x.val, 10);
		assertEquals(p.y.val, 11);
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