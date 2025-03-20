100M:
	find . -size +100M

100M-delete:
	find . -size +100M -delete

100M-delete-recursive:
	find . -size +100M -delete -exec rm -rf {} +

