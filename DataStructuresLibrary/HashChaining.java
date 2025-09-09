/*
 * Derek Hu 
 * Period 6
 * This program simulates a hash table that uses chaining to deal with collisions. This means that
 * in each bucket there is a linked list to hold all items with the same hash values.
 */

import java.util.*;

public class HashChaining<E> {
	
	private LinkedList<E>[] table;
	
	public HashChaining(int tblSize) {
		table = new LinkedList[tblSize];
		
		//creates list for each bucket
		for (int bucket = 0; bucket < tblSize; bucket++)
			table[bucket] = new LinkedList<E>();
	}
	
	//adds item to hash table using chaining
	public boolean add(E item) {	
		table[hashCode(item)].add(item);
		return true;
	}
	
	//if item exists in list at hash value index
	public boolean contains(E item) {	
		return table[hashCode(item)].contains(item);
	}
	
	//removes item if it exists from corresponding bucket list
	public boolean remove(E item) {
		if (contains(item)) {
			table[hashCode(item)].remove(item);		
			return true;
		}
		return false;
	}
	
	//the total steps is the total length of all the buckets of the table added up, so if there was four buckets each of length 3 then it would take 12 steps
	public String toString() {
		String toReturn = "";
		
		//each bucket and prints entire list in bucket
		for (int bucket = 0; bucket < table.length; bucket++) {
			for (E element : table[bucket])
				toReturn += element + ",";
		}
		
		//removes final comma
		if (!toReturn.equals(""))
			toReturn = toReturn.substring(0, toReturn.length() - 1);
		
		return toReturn;
	}
	
	//creates valid hashValue for array
	private int hashCode(E item) {
		return Math.abs(item.hashCode() % table.length);
	}
}