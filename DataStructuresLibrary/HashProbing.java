/*
 * Derek Hu
 * Period 6
 * This program simulates a hash table that uses probing to deal with collisions. Probing takes a 
 * given probing function and alters the index if the hash value of the item already contains another item.
 */

import java.util.*;

public class HashProbing <E>{

	private E[] table;
	private Probeable probeFunction;
	
	public HashProbing(int tblSize, Probeable p){
		table = (E[]) new Object[tblSize];
		probeFunction = p;
	}
	
	//uses probing to add item to next open index
	public boolean add(E item) {
		int index = hashCode(item);
		
		//quits after worst scenario
		for (int bucket = 0; bucket < table.length; bucket++) {
			//can add
			if (table[index] == null) {
				table[index] = item;
				return true;
			}
			
			index = probeFunction.probe(index) % table.length;
		}	
		return false;
	}
	
	//uses hash value and probing to check item exists
	public boolean contains(E item) {
		int index = hashCode(item);
		
		//quits after worst scenario
		for (int bucket = 0; bucket < table.length; bucket++) {
			//value exists
			if (table[index] != null && table[index].equals(item))
				return true;
			
			index = probeFunction.probe(index) % table.length;
		}
		return false;
	}
	
	//searches for item using probing then removes
	public boolean remove(E item) {
		int index = hashCode(item);
		
		//quits after worst scenario
		for (int bucket = 0; bucket < table.length; bucket++) {
			//removes if exists
			if (table[index] != null && table[index].equals(item)) {
				table[index] = null;
				return true;
			}
			
			index = probeFunction.probe(index) % table.length;
		}
		return false;
	}
	
	//total number of steps taken is the same as the length of the hash table
	public String toString() {
		String toReturn = "";
		
		//print each bucket
		for (int bucket = 0; bucket < table.length; bucket++)
			toReturn += table[bucket] + ",";
		
		//remove final comma
		if (!toReturn.equals(""))
			toReturn = toReturn.substring(0, toReturn.length() - 1);
		
		return toReturn;
	}
	
	//creates valid hashValue for array
	private int hashCode(E item) {
		return Math.abs(item.hashCode() % table.length);
	}
}