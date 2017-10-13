import urllib2
import os 


def open_url(url):
	request = urllib2.Request(url)
	request.add_header('User-Agent','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36')
	response = urllib2.urlopen(request)
	html = response.read()
	return html

def get_page(url):
	html = open_url(url)
	a = html.find('current-comment-page') + 23
	b = html.find(']',a)
	return  html[a:b]
	#166

def find_imgs(url):
	html = open_url(url)
	img_addrs = []
	a = html.find('img src=')
	while a != -1:
		b = html.find('.jpg',a,a+255)
		if b != -1:
			img_addrs.append(html[a+9:b+4])
		else:
			b = a + 9
		a = html.find('img src=',b)
	# for each in img_addrs:
	# 	print each
	return img_addrs
	# imgaddrs = []
	# for each in img_addrs:
	#  	each = 'http:' + each
	#  	imgaddrs.append(each)
	# 	print imgaddrs
	# return imgaddrs


def save_imgs(folder,img_addrs):
	for each in img_addrs:
		each = 'http:' + each
		filename = each.split('/')[-1]
		# print filename
		with open(filename,'wb') as f:
			img = open_url(each)
			f.write(img)


def download_mm(folder='ooxx',pages=15):
	os.mkdir(folder)
	os.chdir(folder)

	url = 'http://jandan.net/ooxx/'
 	page_num = int(get_page(url))

 	for i in range(pages):
 		page_num -=i
		page_url = url + 'page-' + str(page_num) + "#comments"
 		img_addrs = find_imgs(page_url)
 		save_imgs(folder,img_addrs)

if __name__ == '__main__':
	download_mm()
	
#test1
