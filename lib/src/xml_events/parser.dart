library xml_events.parser;

import 'package:petitparser/petitparser.dart';

import '../../xml.dart'
    show XmlProductionDefinition, XmlToken, XmlAttributeType;
import '../xml/entities/entity_mapping.dart';
import '../xml/utils/cache.dart';
import 'events/cdata_event.dart';
import 'events/comment_event.dart';
import 'events/declaration_event.dart';
import 'events/doctype_event.dart';
import 'events/end_element_event.dart';
import 'events/event_attribute.dart';
import 'events/processing_event.dart';
import 'events/start_element_event.dart';
import 'events/text_event.dart';

class XmlEventDefinition extends XmlProductionDefinition {
  XmlEventDefinition(XmlEntityMapping entityMapping) : super(entityMapping);

  @override
  Parser start() => ref(characterData)
      .or(ref(startElement))
      .or(ref(endElement))
      .or(ref(comment))
      .or(ref(cdata))
      .or(ref(declaration))
      .or(ref(processing))
      .or(ref(doctype));

  @override
  Parser characterData() =>
      super.characterData().map((each) => XmlTextEvent(each));

  Parser startElement() => XmlToken.openElement
      .toParser()
      .seq(ref(qualified))
      .seq(ref(attributes))
      .seq(ref(spaceOptional))
      .seq(XmlToken.closeElement
          .toParser()
          .or(XmlToken.closeEndElement.toParser()))
      .map((each) => XmlStartElementEvent(
          each[1],
          each[2].cast<XmlEventAttribute>(),
          each[4] == XmlToken.closeEndElement));

  @override
  Parser attribute() => super.attribute().map((each) => XmlEventAttribute(
      each[0],
      each[4][1],
      each[4][0] == '"'
          ? XmlAttributeType.DOUBLE_QUOTE
          : XmlAttributeType.SINGLE_QUOTE));

  Parser endElement() => XmlToken.openEndElement
      .toParser()
      .seq(ref(qualified))
      .seq(ref(spaceOptional))
      .seq(XmlToken.closeElement.toParser())
      .map((each) => XmlEndElementEvent(each[1]));

  @override
  Parser comment() => super.comment().map((each) => XmlCommentEvent(each[1]));

  @override
  Parser cdata() => super.cdata().map((each) => XmlCDATAEvent(each[1]));

  @override
  Parser declaration() => super
      .declaration()
      .map((each) => XmlDeclarationEvent(each[1].cast<XmlEventAttribute>()));

  @override
  Parser processing() =>
      super.processing().map((each) => XmlProcessingEvent(each[1], each[2]));

  @override
  Parser doctype() => super.doctype().map((each) => XmlDoctypeEvent(each[2]));
}

final XmlCache<XmlEntityMapping, Parser> eventParserCache =
    XmlCache((entityMapping) => XmlEventDefinition(entityMapping).build(), 5);
