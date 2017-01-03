require 'active_support/concern'

module UnparsedRun
  extend ActiveSupport::Concern

  included do
    def parses?(fast: true, convert: false)
      dynamodb_info.present? || parse(fast: fast, convert: convert).present?
    end

    # Deprecated; use Run#dynamodb_info, Run#dynamodb_segments, Run#dynamodb_history, and Split#dynamodb_history instead
    def parse(fast: true, convert: false)
      return @parse_cache[fast] if @parse_cache.try(:[], fast).present?
      return @parse_cache[false] if @parse_cache.try(:[], false).present?
      return @convert_cache if @convert_cache.present?

      if !convert
        if fast
          resp = dynamodb_info
          if resp.blank?
            parse_into_dynamodb
            resp = dynamodb_info
          end

          if resp.present?
            return {
              id: resp['id'],
              timer: resp['timer'],
              attempts: resp['attempts'],
              srdc_id: resp['srdc_id'],
              duration: resp['duration_in_seconds'],
              sum_of_best: resp['sum_of_best'],
              splits: dynamodb_segments,
            }.merge(resp)
          end
        end
      end

      # Convert flow below

      Run.programs.each do |timer|
        parse_result = timer::Parser.new.parse(file, fast: fast)
        next if parse_result.blank?

        parse_result[:timer] = timer.to_sym
        assign_attributes(
          program: parse_result[:timer],
          attempts: parse_result[:attempts],
          srdc_id: srdc_id || parse_result[:srdc_id].presence,
          time: parse_result[:splits].map { |split| split.duration }.sum.to_f,
          sum_of_best: parse_result[:splits].map.all? do |split|
          split.best.present?
        end && parse_result[:splits].map do |split|
          split.best
        end.sum.to_f
        )

        if convert
          @convert_cache = parse_result
        else
          populate_category(parse_result[:game], parse_result[:category])
          save
        end

        @parse_cache = (@parse_cache || {}).merge(fast => parse_result)

        if !fast && !convert
          ddb_request = {
            request_items: {
              "segment_histories" => [
                {
                  put_request: {
                    item: {
                      'segment_id' => ''
                    }
                  }
                }
              ]
            }
          }
          segment_histories = parse_result[:splits].map do |segment|
            histories = {}
            (1..parse_result[:attempts]).each do |attempt_no|
              attempt_number = attempt_no + 1
              h = segment.indexed_history[attempt_number.to_s]
              histories[attempt_number] = h
            end
          end
        end
        return parse_result
      end

      {}
    end
  end
end
