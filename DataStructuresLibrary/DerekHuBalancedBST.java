/*
 * Derek Hu
 * Period 6
 * Balanced Binary Search Tree adds the addition balancing element to BSTs. It uses height differentials to calculate what
 * rotations need to be made to ensure that the final tree is balanced. Having a balanced tree allows for log(n) search times.
 */

import java.util.*;

public class DerekHuBalancedBST<E extends Comparable<E>> {
	
	private TreeNode root;
	
	//takes in a subtree that needs to be balanced and rotates based on needs
	private TreeNode balance(TreeNode r) {
		//go left
		if (r.differential < 0) {
			//left
			if (r.left.differential <= 0) 
				return rotateLL(r);
			//right
			else
				return rotateLR(r);
		}
		//go right
		else {
			//right
			if (r.right.differential >= 0) 
				return rotateRR(r);
			//left
			else 
				return rotateRL(r);
		}
	}
	
	//rotation based on if diff leads left left
	private TreeNode rotateLL(TreeNode r) {
		TreeNode leftSubRoot = r.left;
		r.left = leftSubRoot.right;
		leftSubRoot.right = r;
		
		//height fix
		r.updateHeight();
		leftSubRoot.updateHeight();
	
		return leftSubRoot;
	}
	
	//rotation based on if diff leads right right
	private TreeNode rotateRR(TreeNode r) {
		TreeNode rightSubRoot = r.right;
		r.right = rightSubRoot.left;
		rightSubRoot.left = r;
		
		//height fix
		r.updateHeight();
		rightSubRoot.updateHeight();
		
		return rightSubRoot;
	}
	
	//rotation based on if diff leads left right
	private TreeNode rotateLR(TreeNode r) {
		TreeNode finalRoot = r.left.right;
		TreeNode newLeftSub = r.left;
		
		newLeftSub.right = finalRoot.left;
		r.left = finalRoot.right;
		
		finalRoot.left = newLeftSub;
		finalRoot.right = r;
		
		//height fix
		r.updateHeight();
		newLeftSub.updateHeight();
		finalRoot.updateHeight();
		
		return finalRoot;
	}
	
	//rotation based on if diff leads right left
	private TreeNode rotateRL(TreeNode r) {
		TreeNode finalRoot = r.right.left;
		TreeNode newRightSub = r.right;
		
		newRightSub.left = finalRoot.left;
		r.right= finalRoot.left;
		
		finalRoot.right = newRightSub;
		finalRoot.left = r;
		
		//height fix
		r.updateHeight();
		newRightSub.updateHeight();
		finalRoot.updateHeight();
		
		return finalRoot;
	}
	
	//locates minimum value in BST
	public E findMin() {
		return findMinHelper(root).data;
	}
	
	private TreeNode findMinHelper(TreeNode r) {
		if (r == null)
			return null;
		
		//farthest left node
		if (r.left == null)
			return r;
		
		return findMinHelper(r.left);
	}
	
	//puts item into correct in order position in BST
	public void insert(E item) {
		root = insertHelper(root, item);
	}
	
	private TreeNode insertHelper(TreeNode r, E item) {
		//finds insertion spot
		if (r == null)
			return new TreeNode(item, null, null);
		
		int comparison = r.data.compareTo(item);
		
		//sees if item is equal, less, or greater than current
		if (comparison == 0)
			r.count++;
		else if (comparison > 0) 
			r.left = insertHelper(r.left, item);
		else 
			r.right = insertHelper(r.right, item);
		
		r.updateHeight();
		
		if (Math.abs(r.differential) > 1)
			r = balance(r);
		
		return r;
	}
	
	//removes item from BST based on children
	public void remove(E item) {
		root = removeHelper(root, item);
	}
	
	private TreeNode removeHelper(TreeNode r, E item) {
		if (r == null)
			throw new NoSuchElementException("No Node Found");
		
		int comparison = r.data.compareTo(item);
		
		//node to remove is found
		if (comparison == 0)
			
			//more than one
			if (r.count > 1)
				r.count--;
			else 
				return removeNode(r);
		//less than or greater than current node
		else if (comparison > 0) 
			r.left = removeHelper(r.left, item);
		else 
			r.right = removeHelper(r.right, item);
		
		if (r != null) {
			r.updateHeight();
			
			if (Math.abs(r.differential) > 1)
				r = balance(r);
		}
		
		return r;
	}
	
	//removes or replaces node based on if they have 0, 1, or 2 kids
	private TreeNode removeNode(TreeNode toRem) {
		boolean noLeft = toRem.left == null;
		boolean noRight = toRem.right == null;
		TreeNode toReturn = null;
		
		//two kids
		if (!noLeft && !noRight) {
			TreeNode success= findMinHelper(toRem.right);
			int succCount = success.count;

			success.count = 1;		//dups
			toRem.right = removeHelper(toRem.right, success.data);

			toRem.data = success.data;
			toRem.count = succCount;
		}
		//left kid
		else if (!noLeft) {
			toReturn = toRem.left;
			toRem.left = null;
		}
		//right kid
		else if (!noRight) {
			toReturn = toRem.right;
			toRem.right = null;
		}

		return toReturn;
	}
	
	//simulates each node on the binary tree
	public class TreeNode {
		
		private E data;
		private TreeNode left;
		private TreeNode right;
		private int count;
		private int height;
		private int differential;
		
		public TreeNode(E d, TreeNode l, TreeNode r) {
			data = d;
			left = l;
			right = r;
			count = 1;
			height = 1;
			differential = 0;
		}
		
		//corrects height of tree
		public void updateHeight() {
			boolean hasRight = right != null;
			boolean hasLeft = left != null;
			int rightHeight = 0;
			int leftHeight = 0;
			
			//2 kids
			if (hasRight && hasLeft) {
				rightHeight = right.height;
				leftHeight = left.height;
			}
			//1 kid
			else if (hasLeft) 
				leftHeight = left.height;
			else if (hasRight) 
				rightHeight = right.height;
			
			height = Math.max(leftHeight, rightHeight) + 1;
			differential = rightHeight - leftHeight;
		}
	}
}