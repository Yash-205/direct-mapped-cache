// Tag Comparator: a hit needs a valid line AND a matching tag.
module tag_comparator #(
    parameter TAG_W = 22
) (
    input  wire             valid,
    input  wire [TAG_W-1:0] stored_tag,
    input  wire [TAG_W-1:0] addr_tag,
    output wire             hit
);
    assign hit = valid && (stored_tag == addr_tag);
endmodule
