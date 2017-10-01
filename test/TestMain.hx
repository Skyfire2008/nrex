import haxe.unit.TestRunner;
import haxe.unit.TestCase;

import nrex.core.Entity;
import nrex.core.Group;
import nrex.core.Macro;
import nrex.core.Game;

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
		runner.add(new TestAddingGroupGetters());
		runner.add(new TestBuildingGame());

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
			assertTrue(true);
		}catch(e: Dynamic){
			trace(e);
			assertTrue(false);
		}
	}
}

class TestAddingGroupGetters extends TestCase{

	public function testHasIndividualComponents(){
		var e: SimpleEntity=new SimpleEntity();
		try{
			var hp=e.hp;
			var maxHp=e.maxHp;
			var x=e.x;
			var y=e.y;
			assertTrue(true);
		}catch(e: Dynamic){
			trace(e);
			assertTrue(false);
		}
	}

	public function testGroupGetter(){
		var e: SimpleEntity=new SimpleEntity();
		e.x=new IntWrapper(10);
		e.y=new IntWrapper(20);
		e.hp=new IntWrapper(30);
		e.maxHp=new IntWrapper(40);
		var pg=e.posGroup;
		var hg=e.hpGroup;
		assertTrue(pg.x.equals(new IntWrapper(10)));
		assertTrue(pg.y.equals(new IntWrapper(20)));
		assertTrue(hg.hp.equals(new IntWrapper(30)));
		assertTrue(hg.maxHp.equals(new IntWrapper(40)));
	}

	public function testCanChangeComponentsThroughGroups(){
		var e: SimpleEntity=new SimpleEntity();
		e.x=new IntWrapper(0);
		e.y=new IntWrapper(0);
		var pg=e.posGroup;
		pg.x.val=(10);
		pg.y.val=(20);
		assertTrue(e.x.equals(new IntWrapper(10)));
		assertTrue(e.y.equals(new IntWrapper(20)));
	}
}

class TestBuildingGame extends TestCase{

	public function testBuildsGame(){
		var g: Game=new Game();
		assertTrue(true);
	}
}

class HpGroup extends Group{
	public var hp: IntWrapper;
	public var maxHp: IntWrapper;

	//TODO: add support for custom constructors later!
	/*public function new(owner: Entity, maxHp: IntWrapper){
		super(owner);
		this.maxHp=maxHp;
		this.hp=maxHp;
	}*/
}

class PosGroup extends Group{
	public var x: IntWrapper;
	public var y: IntWrapper;
}

@has("HpGroup", "PosGroup")
class SimpleEntity extends Entity{
	
}



class IntWrapper{
	public var val: Int;

	public function new(val: Int){
		this.val=val;
	}

	public function equals(other: IntWrapper){
		return this.val==other.val;
	}
}