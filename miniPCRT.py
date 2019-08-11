# -*- coding:utf-8 -*-
"""
	     ____   ____ ____ _____
	    |  _ \ / ___|  _ \_   _|
	    | |_) | |   | |_) || |
	    |  __/| |___|  _ < | |
	mini|_|    \____|_| \_\|_|

	mini PNG Check & Repair Tool

Project address: https://github.com/sherlly/PCRT
Original Author: sherlly
Project address: https://github.com/drewadwade/TRex
Revised By: Andrew Wade
Revised Date: 11 Aug 2019
"""

import zlib
import struct
import re
import os
import argparse
import itertools
import platform
import sys

def str2hex(s):
	return s.encode('hex').upper()

def int2hex(i):
	return '0x'+hex(i)[2:].upper()

def str2num(s,n=0):
	if n==4:
		return struct.unpack('!I',s)[0]
	else:
		return eval('0x'+str2hex(s))

def WriteFile(filename):
	if os.path.isfile(filename)==True:
		os.remove(filename)
	file = open(filename,'wb+')
	return file

def ReadFile(filename):
	try:
		with open(filename,'rb') as file:
			data=file.read()
	except IOError,e:
		print Termcolor('Error',e[1]+': '+filename)
		return -1
	return data


def Termcolor(flag,sentence):
	# check platform
	system=platform.system()
	if system == 'Linux' or system == 'Darwin':
		if flag=='Notice':
			return "\033[0;34m[%s]\033[0m %s" % (flag,sentence)
		elif flag=='Detected':
			return "\033[0;32m[%s]\033[0m %s" % (flag,sentence)
		elif flag=='Error' or flag == 'Warning' or flag == 'Failed':
			return "\033[0;31m[%s]\033[0m %s" % (flag,sentence)
	else:
		return "[%s] %s" % (flag,sentence)



class PNG(object):

	def __init__(self,in_file='',out_file='',choices='',mode=0):
		self.in_file=in_file
		self.out_file=out_file

	def __del__(self):
		try:
			self.file.close()
		except AttributeError:
			pass


	def GetPicInfo(self,ihdr=''):
		'''
		bits: color depth
		mode: 0:gray[1] 2:RGB[3] 3:Indexed[1](with palette) 4:grey & alpha[2] 6:RGBA[4]
		compression: DEFLATE(LZ77+Huffman)
		filter: 0:None 1:sub X-A 2:up X-B 3:average X-(A+B)/2 4:Paeth p = A + B − C
		C B D
		A X
		'''
		data=self.LoadPNG()
		if data==-1:
			return -1
		if ihdr=='':
			pos,IHDR=self.FindIHDR(data)
			if pos==-1:
				print Termcolor('Detected','Lost IHDR chunk')
				return -1
			length=struct.unpack('!I',IHDR[:4])[0]
			ihdr=IHDR[8:8+length]

		self.width,self.height,self.bits,self.mode,self.compression,self.filter,self.interlace=struct.unpack('!iiBBBBB',ihdr)

		self.interlace=str2num(ihdr[12])
		if self.mode==0 or self.mode==3: # Gray/Index
			self.channel=1
		elif self.mode==2: # RGB
			self.channel=3
		elif self.mode==4: #GA
			self.channel=2
		elif self.mode==6: # RGBA
			self.channel=4
		else:
			self.channel=0

		data=self.LoadPNG()
		if data==-1:
			return -1

	def zlib_decrypt(self,data):
		# Use in IDAT decompress
		z_data=zlib.decompress(data)
		return z_data

	def LoadPNG(self):
		data=ReadFile(self.in_file)
		return data

	def CheckPNG(self):
		data=self.LoadPNG()
		self.file=WriteFile(self.out_file)
		res=self.CheckHeader(data)
		if res == -1:
			print '[Finished] PNG check complete'
			return -1
		res=self.CheckIHDR(data)
		if res == -1:
			print '[Finished] PNG check complete'
			return -1
		print '[Finished] PNG check complete'
		'''check complete'''

	def Checkcrc(self,chunk_type,chunk_data, checksum):
		# CRC-32 computed over the chunk type and chunk data, but not the length
		calc_crc = zlib.crc32(chunk_type+chunk_data) & 0xffffffff
		calc_crc = struct.pack('!I', calc_crc)
		if calc_crc != checksum:
			return calc_crc
		else:
			return None

	def CheckHeader(self,data):
		# Header:89 50 4E 47 0D 0A 1A 0A   %PNG....
		Header=data[:8]
		if str2hex(Header)!='89504E470D0A1A0A':
			print Termcolor('Detected','Wrong PNG header!')
			print 'File header: %s\nCorrect header: 89504E470D0A1A0A'%(str2hex(Header))
			Header='89504E470D0A1A0A'.decode('hex')
			print '[Finished] Now header:%s'%(str2hex(Header))
		else:
			print '[Finished] Correct PNG header'
		self.file.write(Header)
		return 0

	def FindIHDR(self,data):
		pos=data.find('IHDR')
		if pos == -1:
			return -1,-1
		idat_begin=data.find('IDAT')
		if idat_begin != -1:
			IHDR=data[pos-4:idat_begin-4]
		else:
			IHDR=data[pos-4:pos+21]
		return pos,IHDR

	def CheckIHDR(self,data):
		# IHDR:length=13(4 bytes)+chunk_type='IHDR'(4 bytes)+chunk_ihdr(length bytes)+crc(4 bytes)
		# chunk_ihdr=width(4 bytes)+height(4 bytes)+left(5 bytes)
		pos=data.find('IHDR')
		idat_begin=data.find('IDAT')
		if idat_begin != -1:
			IHDR=data[pos-4:idat_begin-4]
			remainder=data[idat_begin-4:]
		else:
			IHDR=data[pos-4:pos+21]
			remainder=data[pos+21:]
		if pos==-1:
			print Termcolor('Detected','Lost IHDR chunk')
			return -1
		length=struct.unpack('!I',IHDR[:4])[0]
		chunk_type=IHDR[4:8]
		chunk_ihdr=IHDR[8:8+length]
		width,height=struct.unpack('!II',chunk_ihdr[:8])
		crc=IHDR[8+length:12+length]
		# check crc
		calc_crc = self.Checkcrc(chunk_type,chunk_ihdr,crc)
		if width > height:
			# fix height
			for h in xrange(height,width):
				chunk_ihdr=IHDR[8:12]+struct.pack('!I',h)+IHDR[16:8+length]
				if self.Checkcrc(chunk_type,chunk_ihdr,crc) != None:
					FIXED=IHDR[:8]+chunk_ihdr+calc_crc+remainder
					print '[Finished] Successfully fix crc'
					break
		else:
			# fix width
			for w in xrange(width,height):
				chunk_ihdr=struct.pack('!I',w)+IHDR[12:8+length]
				if self.Checkcrc(chunk_type,chunk_ihdr,crc) != None:
					FIXED=IHDR[:8]+chunk_ihdr+calc_crc+remainder
					print '[Finished] Successfully fix crc'
					break
		print '[Finished] Correct IHDR CRC (offset: %s): %s'% (int2hex(pos+4+length),str2hex(calc_crc))
		self.file.write(FIXED)
		print '[Finished] IHDR chunk check complete (offset: %s)'%(int2hex(pos-4))

		# get image information
#		self.GetPicInfo(ihdr=chunk_ihdr)

	def CheckIEND(self,data):
		# IEND:length=0(4 bytes)+chunk_type='IEND'(4 bytes)+crc=AE426082(4 bytes)
		standard_IEND='\x00\x00\x00\x00IEND\xae\x42\x60\x82'
		pos=data.find('IEND')
		if pos == -1:
			print Termcolor('Detected','Lost IEND chunk! Try auto fixing...')
			IEND=standard_IEND
			print '[Finished] Now IEND chunk:%s'%(str2hex(IEND))
		else:
			IEND=data[pos-4:pos+8]
			if IEND != standard_IEND:
				print Termcolor('Detected','Error IEND chunk! Try auto fixing...')
				IEND=standard_IEND
				print '[Finished] Now IEND chunk:%s'%(str2hex(IEND))
			else:
				print '[Finished] Correct IEND chunk'
			if data[pos+8:] != '':
				print Termcolor('Detected','Some data (length: %d) append in the end (%s)'%(len(data[pos+8:]),data[pos+8:pos+18]))
				while True:
					msg = Termcolor('Notice','Try extracting them in: <1>File <2>Terminal <3>Quit [default:3] ')
					choice=raw_input(msg)
					if choice == '1':
						filename = raw_input('[File] Input the file name: ')
						file=WriteFile(filename)
						file.write(data[pos+8:])
						print '[Finished] Successfully write in %s'%(filename)
						os.startfile(os.getcwd())
					elif choice == '2':
						print 'data:',data[pos+8:]
						print 'hex(data):',data[pos+8:].encode('hex')
					elif choice == '3' or choice == '':
						break
					else:
						print Termcolor('Error','Illegal choice. Try again.')

		self.file.write(IEND)
		print '[Finished] IEND chunk check complete'
		return 0

if __name__=='__main__':

	parser = argparse.ArgumentParser()
	parser.add_argument('-i', '--input', help='Input file name (*.png) [Select from terminal]')
	parser.add_argument('-o', '--output', default='CRC_FIX.png', help='Output repaired file name [Default: CRC_FIX.png]')
	args = parser.parse_args()

	in_file=args.input
	out_file=args.output

	my_png=PNG(in_file,out_file,mode=0)
	my_png.CheckPNG()
