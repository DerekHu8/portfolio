/*
 * Derek Hu
 * Creates a stack using an array list. Allows user to add, remove and view items in the stack
 * starting from the top going down.
 */

import java.util.*;

public class ArrayStack<E> implements Stack<E> {
	
	private E[] data = (E[]) new Object[10];
	private int topLoc = -1;
	
	//adds element to top of stack
	public void push(E item) {
		
		//checks array is full
		if (topLoc == data.length - 1) {
			E[] copyList = (E[]) new Object[2*data.length];
			
			//deep copy
			for (int i = 0; i < data.length; i++) {
				copyList[i] = data[i];
			}
			data = copyList;
		}
			
		data[topLoc + 1] = item;
		topLoc++;
	}
	
	//removes top of stack and returns element
	public E pop() {
		if (isEmpty())
			throw new NoSuchElementException();
		
		topLoc--;
		return data[topLoc + 1];
	}
	
	//gets top of the stack
	public E peek() {
		if (isEmpty())
			throw new NoSuchElementException();
		
		return data[topLoc];
	}
	
	//checks empty
	public boolean isEmpty() {
		return topLoc == -1;
	}
	
	public class ListNode {
		private E data;
		private ListNode next;
		
		public ListNode(E d, ListNode n) {
			data = d;
			next = n;
		}
	}
}