library xml_events.converters.encoder;

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:xml/xml.dart'
    show XmlToken, encodeXmlText, encodeXmlAttributeValueWithQuotes;

import '../event.dart';
import '../events/cdata_event.dart';
import '../events/comment_event.dart';
import '../events/doctype_event.dart';
import '../events/end_element_event.dart';
import '../events/processing_event.dart';
import '../events/start_element_event.dart';
import '../events/text_event.dart';
import '../visitor.dart';

/// A converter that encodes a list of [XmlEvent] into a string.
class XmlEncoder extends Converter<List<XmlEvent>, String> {
  const XmlEncoder();

  @override
  String convert(List<XmlEvent> input) {
    final accumulator = StringAccumulatorSink();
    final conversion = startChunkedConversion(accumulator);
    conversion.add(input);
    conversion.close();
    return accumulator.string;
  }

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<String> sink) =>
      _XmlEncoderSink(sink);
}

/// A conversion sink for chunked [XmlEvent] encoding.
class _XmlEncoderSink extends ChunkedConversionSink<List<XmlEvent>>
    with XmlEventVisitor {
  _XmlEncoderSink(this.sink);

  final Sink<String> sink;

  @override
  void add(List<XmlEvent> chunk) => chunk.forEach(visit);

  @override
  void close() => sink.close();

  @override
  void visitCDATAEvent(XmlCDATAEvent event) {
    sink.add(XmlToken.openCDATA);
    sink.add(event.text);
    sink.add(XmlToken.closeCDATA);
  }

  @override
  void visitCommentEvent(XmlCommentEvent event) {
    sink.add(XmlToken.openComment);
    sink.add(event.text);
    sink.add(XmlToken.closeComment);
  }

  @override
  void visitDoctypeEvent(XmlDoctypeEvent event) {
    sink.add(XmlToken.openDoctype);
    sink.add(XmlToken.whitespace);
    sink.add(event.text);
    sink.add(XmlToken.closeDoctype);
  }

  @override
  void visitEndElementEvent(XmlEndElementEvent event) {
    sink.add(XmlToken.openEndElement);
    sink.add(event.name);
    sink.add(XmlToken.closeElement);
  }

  @override
  void visitProcessingEvent(XmlProcessingEvent event) {
    sink.add(XmlToken.openProcessing);
    sink.add(event.target);
    if (event.text.isNotEmpty) {
      sink.add(XmlToken.whitespace);
      sink.add(event.text);
    }
    sink.add(XmlToken.closeProcessing);
  }

  @override
  void visitStartElementEvent(XmlStartElementEvent event) {
    sink.add(XmlToken.openElement);
    sink.add(event.name);
    for (var attribute in event.attributes) {
      sink.add(XmlToken.whitespace);
      sink.add(attribute.name);
      sink.add(XmlToken.equals);
      sink.add(encodeXmlAttributeValueWithQuotes(
        attribute.value,
        attribute.attributeType,
      ));
    }
    if (event.isSelfClosing) {
      sink.add(XmlToken.closeEndElement);
    } else {
      sink.add(XmlToken.closeElement);
    }
  }

  @override
  void visitTextEvent(XmlTextEvent event) {
    sink.add(encodeXmlText(event.text));
  }
}