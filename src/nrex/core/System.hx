package nrex.core;

import nrex.ds.LinkedList;

class System<T: Group>{

	private var groups: LinkedList<T>;

	public function new(){
		groups=new LinkedList<T>();
	}

	public function add(group: T){
		groups.add(group);
	}

	public function setup(){
		throw "setup method not implemented";
	}

	public function teardown(){
		throw "teardown method not implemented";
	}

	public function update(group: T){
		throw "update method not implemented";
	}
	
	public function updateAll(){
		var newGroups: LinkedList<T> = new LinkedList<T>();
		for (g in groups.iterator()){
			this.update(g);
			if (g.owner.alive){
				newGroups.add(g);
			}
		}
		groups = newGroups;
	}
}