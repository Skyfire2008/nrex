package nrex.ds;

/**
 * Linked list implementation
 * Copied from msbarpg
 * @author 					Skyfire2008
 */
class LinkedList<T>{
	
	private var head: ListNode<T>;
	private var tail: ListNode<T>;
	
	public var length(get, null): Int;

	/**
	 * Constructor
	 */
	public function new(){
		head=new ListNode<T>(null);
	}
	
	public inline function isEmpty(): Bool{
		return head.next==null;
	}
	
	/**
	 * Adds a new element to the list
	 * @param	elem		New element
	 */
	public inline function add(elem: T): Void{
		var temp: ListNode<T>=new ListNode<T>(elem);
		temp.next=head.next;
		head.next=temp;
	}

	/**
	 * @brief 				Adds a new element to the end of the list
	 * @param 	elem		Element to add
	 */
	/*public inline function push(elem: T): Void{
		var temp: ListNode<T>=new ListNode<T>(elem);
		temp.next=head;

	}*/
	
	/**
	 * @brief 				Gets the element from a specific position in the list
	 * 
	 * @param num			Number of the position
	 * @return 				Element at that position, null, if position out of bounds
	 */
	public inline function get(num: Int): T{
		var result: T=null;
		
		var current: ListNode<T>=head;
		var curNum: Int=0;
		
		while(current.next!=null){
			current=current.next;
			
			if(curNum==num){
				result=current.value;
				break;
			}
			curNum++;
		}
		
		return result;
	}

	public inline function contains(elem: T): Bool{
		var result=false;

		for(i in iterator()){
			if(i==elem){
				result=true;
				break;
			}
		}

		return result;
	}
	
	public inline function iterator(): LinkedListIterator<T>{
		return new LinkedListIterator<T>(head);
	}

	public inline function clear(): Void{
		head=new ListNode<T>(null);
	}

	public inline function concat(other: LinkedList<T>){
		
	}
	
	//GETTERS AND SETTERS:
	
	private inline function get_length(): Int{
		var current: ListNode<T>=head;
		var result: Int=0;
		while(current.hasNext()){
			current=current.next;
			result++;
		}
		
		return result;
	}
	
}

/**
 * Node of linked list
 * @author					Skyfire2008
 */
class ListNode<T>{
	public var value: T;
	public var next: ListNode<T>;
	
	/**
	 * Constructor
	 * @param	value		Cell value
	 */
	public function new(value: T){
		this.value=value;
		this.next=null;
	}
	
	/**
	 * Checks, whether this cell has a next one
	 * @return				true, if next seel is not null, false otherwise
	 */
	public inline function hasNext(): Bool{
		return this.next!=null;
	}
}

/**
 * List iterator
 * @author 					Skyfire2008
 */
class LinkedListIterator<T>{
	var current: ListNode<T>;
	var previous: ListNode<T>;
	var canRemove: Bool;
	
	public function new(current: ListNode<T>){
		this.current=current;
		this.previous=null;
		this.canRemove=false;
	}
	
	/**
	 * Moves iterator to next node and retrieves its value
	 * @return				Next node's value
	 */
	public inline function next(): T{
		previous=current;
		current=current.next;
		canRemove=true;
		return current.value;
	}
	
	public inline function hasNext(): Bool{
		return current.hasNext();
	}
	
	public inline function remove(): Bool{
		if(canRemove){
			previous.next=current.next;
			current=previous;
			canRemove=false;
		}
		
		return !canRemove;
	}
}