package nrex.util;

class Extensions{

	/**
	 * Checks, whether two strings are equal 
	 * @param	a			string 1
	 * @param	b			string 2
	 * @return				true if equal, false oterwise
	 */
	public static inline function equals(a: String, b: String): Bool{
		var result = true;
		
		if (a.length == b.length){
			for (i in 0...a.length){
				if (a.charCodeAt(i) != b.charCodeAt(i)){
					result = false;
					break;
				}
			}
		}else{
			result=false;
		}
		
		return result;
	}
	
}