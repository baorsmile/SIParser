//
//  HTMLParser.m
//  HTMLParserDemo
//
//  Reference StackOverflow
//  Created by 杨晴贺 on 21/01/2017.
//  Copyright © 2017 Silence. All rights reserved.
//

#import "HTMLParser.h"
#import <libxml/HTMLtree.h>

@implementation HTMLNode{
    xmlNode *_node ;
}

- (HTMLNode*)parent{
    return [[HTMLNode alloc] initWithXMLNode:_node->parent];
}

- (HTMLNode*)nextSibling {
    return [[HTMLNode alloc] initWithXMLNode:_node->next];
}

- (HTMLNode*)previousSibling {
    return [[HTMLNode alloc] initWithXMLNode:_node->prev];
}

void setAttributeNamed(xmlNode * node, const char * nameStr, const char * value) {
    char * newVal = (char *)malloc(strlen(value)+1);
    memcpy (newVal, value, strlen(value)+1);
    for(xmlAttrPtr attr = node->properties; NULL != attr; attr = attr->next){
        if (strcmp((char*)attr->name, nameStr) == 0){
            for(xmlNode *child = attr->children; NULL != child; child = child->next){
                free(child->content);
                child->content = (xmlChar*)newVal;
                break;
            }
            break;
        }
    }
}

NSString * getAttributeNamed(xmlNode * node, const char * nameStr){
    for(xmlAttrPtr attr = node->properties; NULL != attr; attr = attr->next){
        if (strcmp((char*)attr->name, nameStr) == 0){
            for(xmlNode * child = attr->children; NULL != child; child = child->next){
                return [NSString stringWithCString:(void*)child->content encoding:NSUTF8StringEncoding];
            }
            break;
        }
    }
    return NULL;
}

-(NSString*)getAttributeNamed:(NSString*)name{
    const char * nameStr = [name UTF8String];
    return getAttributeNamed(_node, nameStr);
}

-(NSString*)className{
    return [self getAttributeNamed:@"class"];
}

-(NSString*)tagName{
    return [NSString stringWithCString:(void*)_node->name encoding:NSUTF8StringEncoding];
}


-(HTMLNode*)firstChild{
    return [[HTMLNode alloc] initWithXMLNode:_node->children];
}


-(void)findChildrenWithAttribute:(const char*)attribute matchingName:(const char*)className inXMLNode:(xmlNode *)node inArray:(NSMutableArray*)array allowPartial:(BOOL)partial{
    xmlNode *cur_node = NULL;
    const char * classNameStr = className;
    
    for (cur_node = node; cur_node; cur_node = cur_node->next){
        for(xmlAttrPtr attr = cur_node->properties; NULL != attr; attr = attr->next){
            
            if (strcmp((char*)attr->name, attribute) == 0){
                for(xmlNode * child = attr->children; NULL != child; child = child->next){
                    
                    BOOL match = NO;
                    if (!partial && strcmp((char*)child->content, classNameStr) == 0)
                        match = YES;
                    else if (partial && strstr ((char*)child->content, classNameStr) != NULL)
                        match = YES;
                    
                    if (match){
                        HTMLNode * nNode = [[HTMLNode alloc] initWithXMLNode:cur_node];
                        [array addObject:nNode];
                        break;
                    }
                }
                break;
            }
        }
        
        [self findChildrenWithAttribute:attribute matchingName:className inXMLNode:cur_node->children inArray:array allowPartial:partial];
    }
    
}

-(void)findChildTags:(NSString*)tagName inXMLNode:(xmlNode *)node inArray:(NSMutableArray*)array{
    xmlNode *cur_node = NULL;
    const char * tagNameStr =  [tagName UTF8String];
    if (tagNameStr == nil)
        return;
    
    for (cur_node = node; cur_node; cur_node = cur_node->next){
        if (cur_node->name && strcmp((char*)cur_node->name, tagNameStr) == 0){
            HTMLNode * node = [[HTMLNode alloc] initWithXMLNode:cur_node];
            [array addObject:node];
            
        }
        [self findChildTags:tagName inXMLNode:cur_node->children inArray:array];
    }
}


-(NSArray*)findChildrenTag:(NSString*)tagName{
    NSMutableArray * array = [NSMutableArray array];
    
    [self findChildTags:tagName inXMLNode:_node->children inArray:array];
    
    return array;
}

-(HTMLNode*)findChildTag:(NSString*)tagName inXMLNode:(xmlNode *)node{
    xmlNode *cur_node = NULL;
    const char * tagNameStr =  [tagName UTF8String];
    
    for (cur_node = node; cur_node; cur_node = cur_node->next){
        if (cur_node && cur_node->name && strcmp((char*)cur_node->name, tagNameStr) == 0){
            return [[HTMLNode alloc] initWithXMLNode:cur_node];
        }
        
        HTMLNode * cNode = [self findChildTag:tagName inXMLNode:cur_node->children];
        if (cNode != NULL){
            return cNode;
        }
    }
    
    return NULL;
}

-(HTMLNode*)findChildTag:(NSString*)tagName{
    return [self findChildTag:tagName inXMLNode:_node->children];
}


-(NSArray*)children{
    xmlNode *cur_node = NULL;
    NSMutableArray * array = [NSMutableArray array];
    
    for (cur_node = _node->children; cur_node; cur_node = cur_node->next){
        HTMLNode * node = [[HTMLNode alloc] initWithXMLNode:cur_node];
        [array addObject:node];
    }
    
    return array;
}

// 调试用
 -(NSString*)description{
	NSString * string = [NSString stringWithFormat:@"<%s>%@\n", _node->name, [self contents]];
	
	for (HTMLNode * child in [self children]){
        string = [string stringByAppendingString:[child description]];
	}
	string = [string stringByAppendingString:[NSString stringWithFormat:@"<%s>\n", _node->name]];
	return string;
 }

-(HTMLNode*)findChildWithAttribute:(const char*)attribute matchingName:(const char*)name inXMLNode:(xmlNode *)node allowPartial:(BOOL)partial{
    xmlNode *cur_node = NULL;
    const char * classNameStr = name;
    if (node == NULL)
        return NULL;
    
    for (cur_node = node; cur_node; cur_node = cur_node->next){
        for(xmlAttrPtr attr = cur_node->properties; NULL != attr; attr = attr->next){
            if (strcmp((char*)attr->name, attribute) == 0){
                for(xmlNode * child = attr->children; NULL != child; child = child->next){
                    BOOL match = NO;
                    if (!partial && strcmp((char*)child->content, classNameStr) == 0)
                        match = YES;
                    else if (partial && strstr ((char*)child->content, classNameStr) != NULL)
                        match = YES;
                    if (match){
                        return [[HTMLNode alloc] initWithXMLNode:cur_node];
                    }
                }
                break;
            }
        }
        HTMLNode * cNode = [self findChildWithAttribute:attribute matchingName:name inXMLNode:cur_node->children allowPartial:partial];
        if (cNode != NULL){
            return cNode;
        }
    }
    return NULL;
}

-(HTMLNode*)findChildWithAttribute:(NSString*)attribute matchingName:(NSString*)className allowPartial:(BOOL)partial{
    return [self findChildWithAttribute:[attribute UTF8String] matchingName:[className UTF8String] inXMLNode:_node->children allowPartial:partial];
}

-(HTMLNode*)findChildOfClass:(NSString*)className{
    HTMLNode * node = [self findChildWithAttribute:"class" matchingName:[className UTF8String]  inXMLNode:_node->children allowPartial:NO];
    return node;
}

-(NSArray*)findChildrenWithAttribute:(NSString*)attribute matchingName:(NSString*)className allowPartial:(BOOL)partial{
    NSMutableArray * array = [NSMutableArray array];
    [self findChildrenWithAttribute:[attribute UTF8String] matchingName:[className UTF8String] inXMLNode:_node->children inArray:array allowPartial:partial];
    return array;
}


-(NSArray*)findChildrenOfClass:(NSString*)className{
    return [self findChildrenWithAttribute:@"class" matchingName:className allowPartial:NO];
}

-(instancetype)initWithXMLNode:(xmlNode*)xmlNode{
    if (self = [super init]){
        _node = xmlNode;
    }
    return self;
}

-(void)appendChildContentsToString:(NSMutableString*)string inNode:(xmlNode*)node{
    if (node == NULL)
        return;
    
    xmlNode *cur_node = NULL;
    for (cur_node = node; cur_node; cur_node = cur_node->next){
        if (cur_node->content){
            [string appendString:[NSString stringWithCString:(void*)cur_node->content encoding:NSUTF8StringEncoding]];
        }
        [self appendChildContentsToString:string inNode:cur_node->children];
    }
}

-(NSString*)contents{
    if (_node->children && _node->children->content){
        return [NSString stringWithCString:(void*)_node->children->content encoding:NSUTF8StringEncoding];
    }
    return nil;
}

HTMLNodeType nodeType(xmlNode * _node){
    if (_node == NULL || _node->name == NULL)
        return HTMLUnkownNode;
    
    const char * tagName = (const char*)_node->name;
    if (strcmp(tagName, "a") == 0)
        return HTMLHrefNode;
    else if (strcmp(tagName, "text") == 0)
        return HTMLTextNode;
    else if (strcmp(tagName, "code") == 0)
        return HTMLCodeNode;
    else if (strcmp(tagName, "span") == 0)
        return HTMLSpanNode;
    else if (strcmp(tagName, "p") == 0)
        return HTMLPNode;
    else if (strcmp(tagName, "ul") == 0)
        return HTMLUlNode;
    else if (strcmp(tagName, "li") == 0)
        return HTMLLiNode;
    else if (strcmp(tagName, "image") == 0)
        return HTMLImageNode;
    else if (strcmp(tagName, "ol") == 0)
        return HTMLOlNode;
    else if (strcmp(tagName, "strong") == 0)
        return HTMLStrongNode;
    else if (strcmp(tagName, "pre") == 0)
        return HTMLPreNode;
    else if (strcmp(tagName, "blockquote") == 0)
        return HTMLBlockQuoteNode;
    else
        return HTMLUnkownNode;
    
}

-(HTMLNodeType)nodetype{
    return nodeType(_node);
}

NSString * allNodeContents(xmlNode*node){
    if (node == NULL)
        return nil;
    
    void * contents = xmlNodeGetContent(node);
    if (contents){
        NSString * string = [NSString stringWithCString:contents encoding:NSUTF8StringEncoding];
        xmlFree(contents);
        return string;
    }
    return @"";
}

-(NSString*)allContents{
    return allNodeContents(_node);
}

NSString * rawContentsOfNode(xmlNode * node){
    xmlBufferPtr buffer = xmlBufferCreateSize(1000);
    xmlOutputBufferPtr buf = xmlOutputBufferCreateBuffer(buffer, NULL);
    htmlNodeDumpOutput(buf, node->doc, node, (const char*)node->doc->encoding);
    xmlOutputBufferFlush(buf);
    NSString * string = nil;
    
    if (buffer->content) {
        string = [[NSString alloc] initWithBytes:(const void *)xmlBufferContent(buffer) length:xmlBufferLength(buffer) encoding:NSUTF8StringEncoding];
    }
    xmlOutputBufferClose(buf);
    xmlBufferFree(buffer);
    return string;
}

-(NSString*)rawContents {
    return rawContentsOfNode(_node);
}

@end

@implementation HTMLParser{
    htmlDocPtr _doc ;
}

-(HTMLNode*)doc{
    if (_doc == NULL)
        return NULL;
    
    return [[HTMLNode alloc] initWithXMLNode:(xmlNode*)_doc];
}

-(HTMLNode*)html{
    if (_doc == NULL)
        return NULL;
    
    return [[self doc] findChildTag:@"html"];
}

-(HTMLNode*)head{
    if (_doc == NULL)
        return NULL;
    return [[self doc] findChildTag:@"head"];
}

-(HTMLNode*)body{
    if (_doc == NULL)
        return NULL;
    return [[self doc] findChildTag:@"body"];
}

-(instancetype)initWithString:(NSString*)string error:(NSError**)error{
    if (self = [super init]){
        _doc = NULL;
        
        if ([string length] > 0){
            CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
            CFStringRef cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc);
            const char *enc = CFStringGetCStringPtr(cfencstr, 0);
            int optionsHtml = HTML_PARSE_RECOVER;
            optionsHtml = optionsHtml | HTML_PARSE_NOERROR;
            optionsHtml = optionsHtml | HTML_PARSE_NOWARNING;
            NSString *str = [self appendMetaCharset:string] ;
            _doc = htmlReadDoc ((xmlChar*)[str UTF8String], NULL, enc, optionsHtml);
        }else{
            if (error) {
                *error = [NSError errorWithDomain:@"HTMLParserdomain" code:1 userInfo:nil];
            }
        }
    }
    
    return self;
}

-(instancetype)initWithData:(NSData*)data error:(NSError**)error{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [self initWithString:str error:error] ;
}

-(instancetype)initWithContentsOfURL:(NSURL*)url error:(NSError**)error{
    NSData * _data = [[NSData alloc] initWithContentsOfURL:url options:0 error:error];
    if (_data == nil || *error){
        return nil;
    }
    self = [self initWithData:_data error:error];
    return self;
}

- (NSString *)appendMetaCharset:(NSString *)str{
    NSArray *strArray = [str componentsSeparatedByString:@"<head>"] ;
    return [NSString stringWithFormat:@"%@ \n <meta charset=\"UTF-8\"> \n %@",strArray.firstObject,strArray.lastObject] ;
}

-(void)dealloc{
    if (_doc){
        xmlFreeDoc(_doc);
    }
}


@end
